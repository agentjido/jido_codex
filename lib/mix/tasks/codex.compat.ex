defmodule Mix.Tasks.Codex.Compat do
  @moduledoc """
  Validate whether the local Codex CLI supports requested transport mode.

      mix codex.compat
      mix codex.compat --transport app_server
  """

  @shortdoc "Validate Codex CLI compatibility"

  use Mix.Task
  alias Jido.Codex.MixTaskHelpers

  @switches [transport: :string]

  @impl true
  def run(args) do
    {opts, _positional, invalid} = OptionParser.parse(args, strict: @switches)
    MixTaskHelpers.validate_options!(invalid)

    transport = parse_transport(opts[:transport])

    case compatibility_module().status(transport) do
      {:ok, metadata} ->
        Mix.shell().info([
          :green,
          "Codex compatibility check passed.",
          :reset,
          "\n",
          "CLI: ",
          metadata.program,
          "\n",
          "Version: ",
          metadata.version,
          "\n",
          "Transport: ",
          Atom.to_string(metadata.transport),
          "\n",
          "Required tokens: ",
          Enum.join(metadata.required_tokens, ", ")
        ])

      {:error, error} ->
        Mix.raise("""
        Codex compatibility check failed.

        #{Exception.message(error)}
        """)
    end
  end

  defp parse_transport(nil), do: :exec
  defp parse_transport("exec"), do: :exec
  defp parse_transport("app_server"), do: :app_server
  defp parse_transport("app-server"), do: :app_server

  defp parse_transport(other) do
    Mix.raise("invalid --transport value: #{other} (expected exec or app_server)")
  end

  defp compatibility_module do
    Application.get_env(:jido_codex, :codex_compat_module, Jido.Codex.Compatibility)
  end
end
