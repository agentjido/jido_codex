defmodule JidoCodex do
  @moduledoc "OpenAI Codex CLI adapter for JidoHarness."

  @doc "Runs a prompt through the Codex adapter."
  def run(prompt, opts \\ []) do
    JidoCodex.Adapter.run(prompt, opts)
  end
end
