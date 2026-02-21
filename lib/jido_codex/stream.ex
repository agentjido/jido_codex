defmodule Jido.Codex.Stream do
  @moduledoc false

  alias Jido.Codex.SessionRegistry
  alias Jido.Harness.Event

  @type stream_opts :: [
          {:provider, atom()},
          {:mapper_module, module()},
          {:session_registry, module()},
          {:disconnect, (pid() | nil -> any())}
        ]

  @doc """
  Builds a normalized harness event stream from a Codex run result context.
  """
  @spec build(map(), stream_opts()) :: Enumerable.t()
  def build(
        %{
          run_result: run_result,
          run_result_module: run_result_module,
          app_server_connection: app_server_connection,
          cancel_mode: cancel_mode
        },
        opts
      )
      when is_list(opts) do
    provider = Keyword.get(opts, :provider, :codex)
    mapper_module = Keyword.fetch!(opts, :mapper_module)
    session_registry = Keyword.get(opts, :session_registry, SessionRegistry)
    disconnect = Keyword.get(opts, :disconnect, fn _connection -> :ok end)

    source_stream = run_result_module.events(run_result)

    Stream.transform(
      source_stream,
      fn -> %{session_id: nil, registered?: false} end,
      fn codex_event, state ->
        case mapper_module.map_event(codex_event, []) do
          {:ok, mapped_events} when is_list(mapped_events) ->
            {mapped_events,
             maybe_register_session(
               state,
               mapped_events,
               run_result,
               run_result_module,
               app_server_connection,
               cancel_mode,
               session_registry
             )}

          {:error, reason} ->
            {[mapper_error_event(provider, reason)], state}
        end
      end,
      fn state ->
        if state.registered? and is_binary(state.session_id), do: session_registry.delete(state.session_id)
        disconnect.(app_server_connection)
      end
    )
  end

  defp mapper_error_event(provider, reason) do
    Event.new!(%{
      type: :session_failed,
      provider: provider,
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
         _cancel_mode,
         _session_registry
       ),
       do: state

  defp maybe_register_session(
         state,
         events,
         run_result,
         run_result_module,
         app_server_connection,
         cancel_mode,
         session_registry
       ) do
    session_id =
      events
      |> Enum.find_value(fn event ->
        if is_binary(event.session_id) and event.session_id != "", do: event.session_id, else: nil
      end)

    if is_binary(session_id) and session_id != "" do
      session_registry.register(
        session_id,
        %{
          run_result: run_result,
          run_result_module: run_result_module,
          app_server_connection: app_server_connection,
          cancel_mode: cancel_mode
        },
        owner: self()
      )

      %{state | session_id: session_id, registered?: true}
    else
      state
    end
  end
end
