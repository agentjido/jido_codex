defmodule Jido.Codex.Adapter do
  @moduledoc """
  `Jido.Harness.Adapter` implementation for OpenAI Codex CLI.
  """

  @behaviour Jido.Harness.Adapter

  alias Jido.Codex.{Compatibility, Error, Execution, Mapper, Options, SessionRegistry, Stream}
  alias Jido.Harness.Capabilities
  alias Jido.Harness.RunRequest
  alias Jido.Harness.RuntimeContract

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
         {:ok, context} <- execution_module().build_context(normalized, execution_deps()) do
      {:ok, stream_module().build(context, stream_opts())}
    end
  rescue
    e in [ArgumentError] ->
      {:error, Error.validation_error("Invalid run request", %{details: Exception.message(e)})}
  end

  @impl true
  @spec cancel(String.t()) :: :ok | {:error, term()}
  def cancel(session_id) when is_binary(session_id) and session_id != "" do
    with {:ok, entry} <- session_registry_module().fetch(session_id) do
      _ = entry.run_result_module.cancel(entry.run_result, entry.cancel_mode)
      maybe_disconnect(entry.app_server_connection)
      session_registry_module().delete(session_id)
      :ok
    else
      {:error, :not_found} ->
        {:error, Error.execution_error("No active Codex session found for cancellation", %{session_id: session_id})}
    end
  end

  def cancel(other) do
    {:error, Error.validation_error("session_id must be a non-empty string", %{value: other})}
  end

  @impl true
  @spec runtime_contract() :: RuntimeContract.t()
  def runtime_contract do
    RuntimeContract.new!(%{
      provider: :codex,
      host_env_required_any: ["OPENAI_API_KEY"],
      host_env_required_all: [],
      sprite_env_forward: ["OPENAI_API_KEY", "GH_TOKEN", "GITHUB_TOKEN"],
      sprite_env_injected: %{
        "GH_PROMPT_DISABLED" => "1",
        "GIT_TERMINAL_PROMPT" => "0"
      },
      runtime_tools_required: ["codex"],
      compatibility_probes: [
        %{
          "name" => "codex_help_exec",
          "command" => "codex --help || codex exec --help",
          "expect_any" => ["exec", "--json"]
        }
      ],
      install_steps: [
        %{
          "tool" => "codex",
          "when_missing" => true,
          "command" =>
            "if command -v npm >/dev/null 2>&1; then npm install -g @openai/codex; else echo 'npm not available'; exit 1; fi"
        }
      ],
      auth_bootstrap_steps: [
        "if [ -n \"${OPENAI_API_KEY:-}\" ]; then printenv OPENAI_API_KEY | codex login --with-api-key >/dev/null 2>&1 || true; fi",
        "codex login status >/dev/null 2>&1 || true"
      ],
      triage_command_template:
        "if command -v timeout >/dev/null 2>&1; then timeout 120 codex exec --json --full-auto - < {{prompt_file}}; else codex exec --json --full-auto - < {{prompt_file}}; fi",
      coding_command_template:
        "if command -v timeout >/dev/null 2>&1; then timeout 180 codex exec --json --dangerously-bypass-approvals-and-sandbox - < {{prompt_file}}; else codex exec --json --dangerously-bypass-approvals-and-sandbox - < {{prompt_file}}; fi",
      success_markers: [
        %{"type" => "turn.completed"},
        %{"type" => "result", "subtype" => "success"}
      ]
    })
  end

  defp execution_deps do
    %{
      codex_module: codex_module(),
      codex_options_module: codex_options_module(),
      codex_thread_module: codex_thread_module(),
      codex_run_result_module: codex_run_result_module(),
      codex_app_server_module: codex_app_server_module()
    }
  end

  defp stream_opts do
    [
      provider: :codex,
      mapper_module: mapper_module(),
      session_registry: session_registry_module(),
      disconnect: &maybe_disconnect/1
    ]
  end

  defp maybe_disconnect(nil), do: :ok

  defp maybe_disconnect(connection) when is_pid(connection) do
    _ = codex_app_server_module().disconnect(connection)
    :ok
  end

  defp mapper_module do
    Application.get_env(:jido_codex, :mapper_module, Mapper)
  end

  defp compatibility_module do
    Application.get_env(:jido_codex, :compatibility_module, Compatibility)
  end

  defp execution_module do
    Application.get_env(:jido_codex, :execution_module, Execution)
  end

  defp stream_module do
    Application.get_env(:jido_codex, :stream_module, Stream)
  end

  defp session_registry_module do
    Application.get_env(:jido_codex, :session_registry_module, SessionRegistry)
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
