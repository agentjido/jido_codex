defmodule JidoCodex.Adapter do
  @moduledoc "JidoHarness.Adapter implementation for OpenAI Codex CLI."
  @behaviour JidoHarness.Adapter

  @impl true
  def id, do: :codex

  @impl true
  def capabilities do
    %{
      streaming?: true,
      tool_calls?: true,
      tool_results?: true,
      thinking?: false,
      resume?: false,
      usage?: false,
      file_changes?: false,
      cancellation?: false
    }
  end

  @impl true
  def run(_request, _opts \\ []) do
    {:error, "not yet implemented"}
  end
end
