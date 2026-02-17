defmodule Jido.Codex.CompatibilityTest do
  use ExUnit.Case, async: false

  alias Jido.Codex.Compatibility
  alias Jido.Codex.Error.ConfigError
  alias Jido.Codex.Test.{StubCLI, StubCommand}

  setup do
    old_cli_module = Application.get_env(:jido_codex, :codex_cli_module)
    old_command_module = Application.get_env(:jido_codex, :codex_command_module)
    old_cli_resolve = Application.get_env(:jido_codex, :stub_cli_resolve)
    old_command_run = Application.get_env(:jido_codex, :stub_command_run)

    Application.put_env(:jido_codex, :codex_cli_module, StubCLI)
    Application.put_env(:jido_codex, :codex_command_module, StubCommand)

    on_exit(fn ->
      restore_env(:jido_codex, :codex_cli_module, old_cli_module)
      restore_env(:jido_codex, :codex_command_module, old_command_module)
      restore_env(:jido_codex, :stub_cli_resolve, old_cli_resolve)
      restore_env(:jido_codex, :stub_command_run, old_command_run)
    end)

    :ok
  end

  test "returns error when CLI is missing" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:error, :enoent} end)

    assert {:error, %ConfigError{key: :codex_cli}} = Compatibility.status(:exec)
    assert Compatibility.compatible?(:exec) == false
    assert {:error, %ConfigError{key: :codex_cli}} = Compatibility.check(:exec)
  end

  test "checks exec compatibility tokens" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "codex exec --json app-server"}
      _program, ["--version"], _opts -> {:ok, "0.10.1"}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:ok, status} = Compatibility.status(:exec)
    assert status.transport == :exec
    assert status.version == "0.10.1"
    assert Compatibility.check(:exec) == :ok
    assert Compatibility.assert_compatible!(:exec) == :ok
  end

  test "checks app_server compatibility tokens" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "codex app-server"}
      _program, ["--version"], _opts -> {:ok, "0.10.1"}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:ok, status} = Compatibility.status(:app_server)
    assert status.transport == :app_server
  end

  test "accepts string transport aliases" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "codex exec --json app-server"}
      _program, ["--version"], _opts -> {:ok, "0.10.1"}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:ok, %{transport: :exec}} = Compatibility.status("exec")
    assert {:ok, %{transport: :app_server}} = Compatibility.status("app_server")
    assert {:ok, %{transport: :app_server}} = Compatibility.status("app-server")
  end

  test "returns compatibility error when required tokens are missing" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "codex exec"}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:error, %ConfigError{key: :codex_cli_transport_compatibility}} = Compatibility.status(:exec)
  end

  test "returns error when help output cannot be read" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn
      _program, ["--help"], _opts -> {:error, :boom}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:error, %ConfigError{key: :codex_cli_help}} = Compatibility.status(:exec)
  end

  test "returns unknown version when version command fails" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn
      _program, ["--help"], _opts -> {:ok, "codex exec --json app-server"}
      _program, ["--version"], _opts -> {:error, :boom}
      _program, _args, _opts -> {:ok, "ok"}
    end)

    assert {:ok, status} = Compatibility.status(:exec)
    assert status.version == "unknown"
  end

  test "assert_compatible!/1 raises on invalid transport" do
    assert_raise ConfigError, fn ->
      Compatibility.assert_compatible!(:bogus)
    end
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
