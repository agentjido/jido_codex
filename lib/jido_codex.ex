defmodule JidoCodex do
  @moduledoc """
  OpenAI Codex CLI adapter for JidoHarness.

  Provides a thin wrapper around the Codex SDK, translating its events
  into normalized JidoHarness.Event structs.

  ## Usage

      {:ok, events} = JidoCodex.run("your prompt")
      Stream.each(events, &handle_event/1)
  """

  @doc """
  Runs a prompt through the Codex adapter.

  Delegates to `JidoCodex.Adapter.run/2` to handle the actual execution
  and event translation from the Codex SDK to JidoHarness events.

  ## Parameters

    * `prompt` - The prompt string to send to Codex
    * `opts` - Keyword list of options (default: `[]`)

  ## Returns

    * `{:ok, stream}` - A stream of normalized JidoHarness.Event structs
    * `{:error, reason}` - An error tuple on failure
  """
  @spec run(String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(prompt, opts \\ []) do
    JidoCodex.Adapter.run(prompt, opts)
  end
end
