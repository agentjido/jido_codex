defmodule JidoCodex.Adapter do
  @moduledoc """
  JidoHarness.Adapter implementation for OpenAI Codex.

  This module adapts the Codex SDK to implement the JidoHarness.Adapter behaviour,
  translating Codex events into normalized JidoHarness.Event structs.
  """

  require Logger

  @doc """
  Runs a prompt through the Codex SDK and translates events.

  ## Parameters

    * `prompt` - The prompt string
    * `opts` - Keyword list of options

  ## Returns

    * `{:ok, stream}` - A stream of JidoHarness.Event structs
    * `{:error, reason}` - Error tuple on failure
  """
  @spec run(String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(prompt, opts \\ []) when is_binary(prompt) and is_list(opts) do
    # TODO: Implement Codex SDK integration
    # 1. Call CodexSdk.execute/2 with prompt and opts
    # 2. Map returned events via JidoCodex.Mapper.map_event/1
    # 3. Return stream of normalized events

    Logger.debug("JidoCodex.Adapter.run/2 called", prompt: prompt, opts: opts)
    {:ok, Stream.flat_map([], & &1)}
  end
end
