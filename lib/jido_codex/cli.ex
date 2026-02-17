defmodule Jido.Codex.CLI do
  @moduledoc false

  @doc false
  @spec resolve() :: {:ok, %{program: String.t()}} | {:error, term()}
  def resolve do
    options_module = Application.get_env(:jido_codex, :codex_options_module, Codex.Options)

    with {:ok, options} <- options_module.new(%{}),
         {:ok, path} <- options_module.codex_path(options) do
      {:ok, %{program: path}}
    else
      _ ->
        case System.find_executable("codex") do
          nil -> {:error, :enoent}
          path -> {:ok, %{program: path}}
        end
    end
  end
end
