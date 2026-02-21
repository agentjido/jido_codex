defmodule Jido.Codex.Execution do
  @moduledoc false

  alias Jido.Codex.{Error, Options}

  @type deps :: %{
          required(:codex_module) => module(),
          required(:codex_options_module) => module(),
          required(:codex_thread_module) => module(),
          required(:codex_run_result_module) => module(),
          required(:codex_app_server_module) => module()
        }

  @doc """
  Builds Codex execution context, including run result and optional app-server connection.
  """
  @spec build_context(Options.t(), deps()) :: {:ok, map()} | {:error, term()}
  def build_context(%Options{} = options, deps) when is_map(deps) do
    with {:ok, codex_opts} <- deps.codex_options_module.new(options.codex_opts),
         {:ok, app_server_connection} <- maybe_connect_app_server(options, codex_opts, deps.codex_app_server_module),
         thread_opts <- build_thread_opts(options.thread_opts, options.transport, app_server_connection),
         {:ok, thread} <- build_thread(options, codex_opts, thread_opts, deps.codex_module),
         {:ok, run_result} <- deps.codex_thread_module.run_streamed(thread, options.prompt, options.turn_opts) do
      {:ok,
       %{
         run_result: run_result,
         run_result_module: deps.codex_run_result_module,
         app_server_connection: app_server_connection,
         cancel_mode: options.cancel_mode
       }}
    else
      {:error, _} = error ->
        error
    end
  end

  defp maybe_connect_app_server(%Options{transport: :exec}, _codex_opts, _codex_app_server_module), do: {:ok, nil}

  defp maybe_connect_app_server(
         %Options{transport: :app_server, app_server: app_server_opts},
         codex_opts,
         codex_app_server_module
       ) do
    opts = Enum.to_list(app_server_opts)

    case codex_app_server_module.connect(codex_opts, opts) do
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

  defp build_thread(%Options{resume_last: true}, codex_opts, thread_opts, codex_module) do
    codex_module.resume_thread(:last, codex_opts, thread_opts)
  end

  defp build_thread(%Options{thread_id: thread_id}, codex_opts, thread_opts, codex_module)
       when is_binary(thread_id) and thread_id != "" do
    codex_module.resume_thread(thread_id, codex_opts, thread_opts)
  end

  defp build_thread(_options, codex_opts, thread_opts, codex_module) do
    codex_module.start_thread(codex_opts, thread_opts)
  end
end
