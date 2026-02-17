defmodule Mix.Tasks.Codex.Install do
  @moduledoc """
  Check for the Codex CLI and provide installation instructions.

      mix codex.install
  """

  @shortdoc "Check Codex CLI installation and provide setup instructions"

  use Mix.Task

  @impl true
  def run(_args) do
    case cli_module().resolve() do
      {:ok, spec} ->
        Mix.shell().info(["Codex CLI found: ", :green, spec.program, :reset])

      {:error, _} ->
        Mix.shell().info([
          :yellow,
          "Codex CLI not found.",
          :reset,
          "\n\n",
          "Install the Codex CLI using one of these methods:\n\n",
          "  npm install -g @openai/codex\n",
          "  brew install codex\n\n",
          "After installation, run this task again to verify:\n\n",
          "  mix codex.install\n"
        ])
    end
  end

  defp cli_module do
    Application.get_env(:jido_codex, :codex_cli_module, Jido.Codex.CLI)
  end
end
