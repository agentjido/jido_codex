defmodule Jido.Codex.Adapter do
  @moduledoc """
  `Jido.Harness.Adapter` implementation for OpenAI Codex CLI.
  """

  @behaviour Jido.Harness.Adapter

  alias Jido.Codex.{Compatibility, Error, Mapper, Options, SessionRegistry}
  alias Jido.Harness.Capabilities
  alias Jido.Harness.Event
  alias Jido.Harness.RunRequest

  @impl true
  @spec id() :: atom()
  def id, do: :codex

  @impl true
  @spec capabilities() :: map()
  def capabilities do
    %Capabilities{
      streaming?: true,
      tool_calls?: true,
      tool_results?: true,
      thinking?: true,
      resume?: true,
      usage?: true,
      file_changes?: true,
      cancellation?: true
    }
  end

  @impl true
  @spec run(RunRequest.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(%RunRequest{} = request, opts \\ []) when is_list(opts) do
    with {:ok, normalized} <- Options.from_run_request(request, opts),
         :ok <- compatibility_module().check(normalized.transport),
         {:ok, context} <- build_execution_context(normalized) do
      {:ok, build_event_stream(context)}
    end
  rescue
    e in [ArgumentError] -> {:error, Error.validation_error("Invalid run request", %{details: Exception.message(e)})}
  end

  @impl true
  @spec cancel(String.t()) :: :ok | {:error, term()}
  def cancel(session_id) when is_binary(session_id) and session_id != "" do
    with {:ok, entry} <- SessionRegistry.fetch(session_id) do
      _ = entry.run_result_module.cancel(entry.run_result, entry.cancel_mode)
      maybe_disconnect(entry.app_server_connection)
      SessionRegistry.delete(session_id)
      :ok
    else
      {:error, :not_found} ->
        {:error, Error.execution_error("No active Codex session found for cancellation", %{session_id: session_id})}
    end
  end

  def cancel(other) do
    {:error, Error.validation_error("session_id must be a non-empty string", %{value: other})}
  end

  defp build_execution_context(%Options{} = options) do
    with {:ok, codex_opts} <- codex_options_module().new(options.codex_opts),
         {:ok, app_server_connection} <- maybe_connect_app_server(options, codex_opts),
         thread_opts <- build_thread_opts(options.thread_opts, options.transport, app_server_connection),
         {:ok, thread} <- build_thread(options, codex_opts, thread_opts),
         {:ok, run_result} <- codex_thread_module().run_streamed(thread, options.prompt, options.turn_opts) do
      {:ok,
       %{
         run_result: run_result,
         run_result_module: codex_run_result_module(),
         app_server_connection: app_server_connection,
         cancel_mode: options.cancel_mode
       }}
    else
      {:error, _} = error ->
        error
    end
  end

  defp maybe_connect_app_server(%Options{transport: :exec}, _codex_opts), do: {:ok, nil}

  defp maybe_connect_app_server(%Options{transport: :app_server, app_server: app_server_opts}, codex_opts) do
    opts = to_keyword(app_server_opts)

    case codex_app_server_module().connect(codex_opts, opts) do
      {:ok, connection} ->
        {:ok, connection}

      {:error, reason} ->
        {:error, Error.execution_error("Unable to establish Codex app-server connection", %{details: reason})}
    end
  end

  defp build_thread_opts(thread_opts, :exec, _app_server_connection), do: thread_opts

  defp build_thread_opts(thread_opts, :app_server, app_server_connection) when is_pid(app_server_connection) do
    Map.put(thread_opts, :transport, {:app_server, app_server_connection})
  end

  defp build_thread(%Options{resume_last: true}, codex_opts, thread_opts) do
    codex_module().resume_thread(:last, codex_opts, thread_opts)
  end

  defp build_thread(%Options{thread_id: thread_id}, codex_opts, thread_opts)
       when is_binary(thread_id) and thread_id != "" do
    codex_module().resume_thread(thread_id, codex_opts, thread_opts)
  end

  defp build_thread(_options, codex_opts, thread_opts) do
    codex_module().start_thread(codex_opts, thread_opts)
  end

  defp build_event_stream(%{
         run_result: run_result,
         run_result_module: run_result_module,
         app_server_connection: app_server_connection,
         cancel_mode: cancel_mode
       }) do
    source_stream = run_result_module.events(run_result)
    mapper = mapper_module()

    Stream.transform(
      source_stream,
      fn -> %{session_id: nil, registered?: false} end,
      fn codex_event, state ->
        case mapper.map_event(codex_event, []) do
          {:ok, mapped_events} when is_list(mapped_events) ->
            {mapped_events,
             maybe_register_session(
               state,
               mapped_events,
               run_result,
               run_result_module,
               app_server_connection,
               cancel_mode
             )}

          {:error, reason} ->
            error_event = mapper_error_event(reason)
            {[error_event], state}
        end
      end,
      fn state ->
        if state.registered? and is_binary(state.session_id), do: SessionRegistry.delete(state.session_id)
        maybe_disconnect(app_server_connection)
      end
    )
  end

  defp mapper_error_event(reason) do
    Event.new!(%{
      type: :session_failed,
      provider: :codex,
      session_id: nil,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      payload: %{"error" => inspect(reason)},
      raw: reason
    })
  end

  defp maybe_register_session(
         %{registered?: true} = state,
         _events,
         _run_result,
         _run_result_module,
         _conn,
         _cancel_mode
       ),
       do: state

  defp maybe_register_session(state, events, run_result, run_result_module, app_server_connection, cancel_mode) do
    session_id =
      events
      |> Enum.find_value(fn event ->
        if is_binary(event.session_id) and event.session_id != "", do: event.session_id, else: nil
      end)

    if is_binary(session_id) and session_id != "" do
      SessionRegistry.register(session_id, %{
        run_result: run_result,
        run_result_module: run_result_module,
        app_server_connection: app_server_connection,
        cancel_mode: cancel_mode
      })

      %{state | session_id: session_id, registered?: true}
    else
      state
    end
  end

  defp maybe_disconnect(nil), do: :ok

  defp maybe_disconnect(connection) when is_pid(connection) do
    _ = codex_app_server_module().disconnect(connection)
    :ok
  end

  defp to_keyword(map), do: Enum.to_list(map)

  defp mapper_module do
    Application.get_env(:jido_codex, :mapper_module, Mapper)
  end

  defp compatibility_module do
    Application.get_env(:jido_codex, :compatibility_module, Compatibility)
  end

  defp codex_module do
    Application.get_env(:jido_codex, :codex_module, Codex)
  end

  defp codex_options_module do
    Application.get_env(:jido_codex, :codex_options_module, Codex.Options)
  end

  defp codex_thread_module do
    Application.get_env(:jido_codex, :codex_thread_module, Codex.Thread)
  end

  defp codex_run_result_module do
    Application.get_env(:jido_codex, :codex_run_result_module, Codex.RunResultStreaming)
  end

  defp codex_app_server_module do
    Application.get_env(:jido_codex, :codex_app_server_module, Codex.AppServer)
  end
end
