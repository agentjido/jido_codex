defmodule Jido.Codex.CLITest do
  use ExUnit.Case, async: false

  alias Jido.Codex.CLI
  alias Jido.Codex.Test.StubCodexOptions

  setup do
    old_options_module = Application.get_env(:jido_codex, :codex_options_module)
    old_new = Application.get_env(:jido_codex, :stub_codex_options_new)
    old_path = Application.get_env(:jido_codex, :stub_codex_options_path)

    Application.put_env(:jido_codex, :codex_options_module, StubCodexOptions)

    on_exit(fn ->
      restore_env(:jido_codex, :codex_options_module, old_options_module)
      restore_env(:jido_codex, :stub_codex_options_new, old_new)
      restore_env(:jido_codex, :stub_codex_options_path, old_path)
    end)

    :ok
  end

  test "resolve uses Codex.Options path when available" do
    Application.put_env(:jido_codex, :stub_codex_options_new, fn _attrs -> {:ok, %{}} end)
    Application.put_env(:jido_codex, :stub_codex_options_path, fn -> {:ok, "/tmp/codex"} end)

    assert {:ok, %{program: "/tmp/codex"}} = CLI.resolve()
  end

  test "resolve falls back to System.find_executable" do
    Application.put_env(:jido_codex, :stub_codex_options_new, fn _attrs -> {:error, :bad} end)

    result = CLI.resolve()
    assert match?({:ok, %{program: _}}, result) or match?({:error, :enoent}, result)
  end

  test "resolve returns enoent when fallback executable is missing" do
    old_path = System.get_env("PATH")

    on_exit(fn ->
      if is_nil(old_path), do: System.delete_env("PATH"), else: System.put_env("PATH", old_path)
    end)

    System.put_env("PATH", "")
    Application.put_env(:jido_codex, :stub_codex_options_new, fn _attrs -> {:error, :bad} end)

    assert {:error, :enoent} = CLI.resolve()
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
