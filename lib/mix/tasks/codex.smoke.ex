defmodule Mix.Tasks.Codex.Smoke do
  @moduledoc """
  Execute a minimal Codex prompt for smoke validation.

      mix codex.smoke "Say hello"
      mix codex.smoke "Summarize this repo" --cwd /path --transport app_server --timeout 30000
  """

  @shortdoc "Run a minimal Codex smoke prompt"

  use Mix.Task
  alias Jido.Codex.MixTaskHelpers

  @switches [cwd: :string, transport: :string, timeout: :integer]

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, invalid} = OptionParser.parse(args, strict: @switches)
    MixTaskHelpers.validate_options!(invalid)

    prompt =
      case positional do
        [value] -> value
        _ -> Mix.raise("expected exactly one PROMPT argument")
      end

    metadata = %{
      "codex" => %{
        "transport" => normalize_transport(opts[:transport]),
        "turn_opts" => timeout_turn_opts(opts[:timeout])
      }
    }

    run_opts =
      []
      |> maybe_put(:cwd, opts[:cwd])
      |> Keyword.put(:metadata, metadata)

    Mix.shell().info(["Running Codex smoke prompt..."])

    case codex_module().run(prompt, run_opts) do
      {:ok, stream} ->
        count = stream |> Enum.take(10_000) |> length()
        Mix.shell().info("Smoke run completed with #{count} normalized events.")

      {:error, reason} ->
        Mix.raise("Codex smoke run failed: #{format_error(reason)}")
    end
  end

  defp normalize_transport(nil), do: "exec"
  defp normalize_transport("exec"), do: "exec"
  defp normalize_transport("app_server"), do: "app_server"
  defp normalize_transport("app-server"), do: "app_server"

  defp normalize_transport(other) do
    Mix.raise("invalid --transport value: #{other} (expected exec or app_server)")
  end

  defp timeout_turn_opts(nil), do: %{}
  defp timeout_turn_opts(value), do: %{"timeout_ms" => value}

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp format_error(%{message: message}) when is_binary(message), do: message
  defp format_error(reason), do: inspect(reason)

  defp codex_module do
    Application.get_env(:jido_codex, :codex_public_module, Jido.Codex)
  end
end
