defmodule Jido.Codex do
  @moduledoc """
  OpenAI Codex CLI adapter for Jido.Harness.

  This package provides:

  - `run/2` and `run_request/2` convenience wrappers around adapter execution
  - Compatibility checks for Codex CLI execution modes
  - Cancellation for active streamed sessions
  """

  @version "0.1.0"

  alias Jido.Codex.{Adapter, Compatibility}
  alias Jido.Harness.RunRequest

  @request_keys [
    :cwd,
    :model,
    :max_turns,
    :timeout_ms,
    :system_prompt,
    :allowed_tools,
    :attachments,
    :metadata
  ]

  @doc "Returns the package version."
  @spec version() :: String.t()
  def version, do: @version

  @doc "Returns true if the Codex CLI binary can be found."
  @spec cli_installed?() :: boolean()
  def cli_installed?, do: Compatibility.cli_installed?()

  @doc "Returns true if the local Codex CLI supports the requested transport."
  @spec compatible?(:exec | :app_server) :: boolean()
  def compatible?(transport \\ :exec), do: Compatibility.compatible?(transport)

  @doc "Raises `Jido.Codex.Error.ConfigError` if compatibility checks fail."
  @spec assert_compatible!(:exec | :app_server) :: :ok | no_return()
  def assert_compatible!(transport \\ :exec), do: Compatibility.assert_compatible!(transport)

  @doc "Runs a prompt through the Codex adapter."
  @spec run(String.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run(prompt, opts \\ []) when is_binary(prompt) and is_list(opts) do
    request_opts = Keyword.take(opts, @request_keys)
    adapter_opts = Keyword.drop(opts, @request_keys)

    with {:ok, request} <- RunRequest.new(Map.new([{:prompt, prompt} | request_opts])) do
      run_request(request, adapter_opts)
    end
  end

  @doc "Runs an already-built `%Jido.Harness.RunRequest{}` through the Codex adapter."
  @spec run_request(RunRequest.t(), keyword()) :: {:ok, Enumerable.t()} | {:error, term()}
  def run_request(%RunRequest{} = request, opts \\ []) when is_list(opts) do
    adapter_module().run(request, opts)
  end

  @doc "Cancels an active streamed run by session id."
  @spec cancel(String.t()) :: :ok | {:error, term()}
  def cancel(session_id), do: adapter_module().cancel(session_id)

  defp adapter_module do
    Application.get_env(:jido_codex, :adapter_module, Adapter)
  end
end
