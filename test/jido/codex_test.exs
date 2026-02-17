defmodule Jido.CodexTest do
  use ExUnit.Case

  alias Jido.Codex.Test.StubAdapter

  setup do
    old_adapter_module = Application.get_env(:jido_codex, :adapter_module)
    old_adapter_run = Application.get_env(:jido_codex, :stub_adapter_run)
    old_adapter_cancel = Application.get_env(:jido_codex, :stub_adapter_cancel)
    old_cli_module = Application.get_env(:jido_codex, :codex_cli_module)
    old_command_module = Application.get_env(:jido_codex, :codex_command_module)
    old_cli_resolve = Application.get_env(:jido_codex, :stub_cli_resolve)
    old_command_run = Application.get_env(:jido_codex, :stub_command_run)

    Application.put_env(:jido_codex, :adapter_module, StubAdapter)
    Application.put_env(:jido_codex, :codex_cli_module, Jido.Codex.Test.StubCLI)
    Application.put_env(:jido_codex, :codex_command_module, Jido.Codex.Test.StubCommand)

    on_exit(fn ->
      restore_env(:jido_codex, :adapter_module, old_adapter_module)
      restore_env(:jido_codex, :stub_adapter_run, old_adapter_run)
      restore_env(:jido_codex, :stub_adapter_cancel, old_adapter_cancel)
      restore_env(:jido_codex, :codex_cli_module, old_cli_module)
      restore_env(:jido_codex, :codex_command_module, old_command_module)
      restore_env(:jido_codex, :stub_cli_resolve, old_cli_resolve)
      restore_env(:jido_codex, :stub_command_run, old_command_run)
    end)

    :ok
  end

  test "version/0 returns semver string" do
    assert is_binary(Jido.Codex.version())
    assert Jido.Codex.version() =~ ~r/^\d+\.\d+\.\d+$/
  end

  test "run/2 builds run request and delegates to adapter" do
    Application.put_env(:jido_codex, :stub_adapter_run, fn request, opts ->
      send(self(), {:adapter_run, request, opts})
      {:ok, []}
    end)

    assert {:ok, []} = Jido.Codex.run("hello", cwd: "/tmp", transport: "exec")

    assert_receive {:adapter_run, request, opts}
    assert request.prompt == "hello"
    assert request.cwd == "/tmp"
    assert opts == [transport: "exec"]
  end

  test "run_request/2 delegates directly to adapter" do
    request = Jido.Harness.RunRequest.new!(%{prompt: "hello", metadata: %{}})

    Application.put_env(:jido_codex, :stub_adapter_run, fn ^request, opts ->
      send(self(), {:adapter_run_request, opts})
      {:ok, []}
    end)

    assert {:ok, []} = Jido.Codex.run_request(request, foo: :bar)
    assert_receive {:adapter_run_request, [foo: :bar]}
  end

  test "cancel/1 delegates to adapter" do
    Application.put_env(:jido_codex, :stub_adapter_cancel, fn session_id ->
      send(self(), {:adapter_cancel, session_id})
      :ok
    end)

    assert :ok = Jido.Codex.cancel("session-1")
    assert_receive {:adapter_cancel, "session-1"}
  end

  test "compatibility helpers delegate through compatibility module behavior" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "codex exec --json app-server"}
      _program, ["--version"], _opts -> {:ok, "0.10.1"}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert Jido.Codex.cli_installed?() == true
    assert Jido.Codex.compatible?(:exec) == true
    assert :ok = Jido.Codex.assert_compatible!(:exec)
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
