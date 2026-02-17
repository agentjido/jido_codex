defmodule Mix.Tasks.CodexTasksTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  alias Jido.Codex.Test.{StubCLI, StubCompatibility, StubPublicCodex}
  alias Mix.Tasks.Codex.{Compat, Install, Smoke}

  setup do
    old_cli_module = Application.get_env(:jido_codex, :codex_cli_module)
    old_compat_module = Application.get_env(:jido_codex, :codex_compat_module)
    old_public_module = Application.get_env(:jido_codex, :codex_public_module)
    old_stub_cli_resolve = Application.get_env(:jido_codex, :stub_cli_resolve)
    old_stub_compat_status = Application.get_env(:jido_codex, :stub_compat_status)
    old_stub_public_codex_run = Application.get_env(:jido_codex, :stub_public_codex_run)

    Application.put_env(:jido_codex, :codex_cli_module, StubCLI)
    Application.put_env(:jido_codex, :codex_compat_module, StubCompatibility)
    Application.put_env(:jido_codex, :codex_public_module, StubPublicCodex)

    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_compat_status, fn transport ->
      {:ok, %{program: "/tmp/codex", version: "0.10.1", transport: transport, required_tokens: ["exec"]}}
    end)

    Application.put_env(:jido_codex, :stub_public_codex_run, fn prompt, opts ->
      send(self(), {:smoke_run, prompt, opts})
      {:ok, [%{type: :session_started}]}
    end)

    on_exit(fn ->
      restore_env(:jido_codex, :codex_cli_module, old_cli_module)
      restore_env(:jido_codex, :codex_compat_module, old_compat_module)
      restore_env(:jido_codex, :codex_public_module, old_public_module)
      restore_env(:jido_codex, :stub_cli_resolve, old_stub_cli_resolve)
      restore_env(:jido_codex, :stub_compat_status, old_stub_compat_status)
      restore_env(:jido_codex, :stub_public_codex_run, old_stub_public_codex_run)
    end)

    :ok
  end

  test "mix codex.install prints found message" do
    Mix.Task.reenable("codex.install")

    output =
      capture_io(fn ->
        Install.run([])
      end)

    assert output =~ "Codex CLI found"
    assert output =~ "/tmp/codex"
  end

  test "mix codex.install prints install instructions when missing" do
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:error, :enoent} end)

    Mix.Task.reenable("codex.install")

    output =
      capture_io(fn ->
        Install.run([])
      end)

    assert output =~ "Codex CLI not found"
    assert output =~ "mix codex.install"
  end

  test "mix codex.compat prints success" do
    Mix.Task.reenable("codex.compat")

    output =
      capture_io(fn ->
        Compat.run(["--transport", "exec"])
      end)

    assert output =~ "Codex compatibility check passed"
    assert output =~ "Transport: exec"
  end

  test "mix codex.compat accepts app_server aliases" do
    Mix.Task.reenable("codex.compat")

    output1 =
      capture_io(fn ->
        Compat.run(["--transport", "app_server"])
      end)

    output2 =
      capture_io(fn ->
        Mix.Task.reenable("codex.compat")
        Compat.run(["--transport", "app-server"])
      end)

    assert output1 =~ "Transport: app_server"
    assert output2 =~ "Transport: app_server"
  end

  test "mix codex.compat raises on bad transport" do
    Mix.Task.reenable("codex.compat")

    assert_raise Mix.Error, ~r/invalid --transport value/, fn ->
      capture_io(fn ->
        Compat.run(["--transport", "bad"])
      end)
    end
  end

  test "mix codex.compat validates unknown options" do
    Mix.Task.reenable("codex.compat")

    assert_raise Mix.Error, ~r/invalid options: --bad/, fn ->
      capture_io(fn ->
        Compat.run(["--bad"])
      end)
    end

    Mix.Task.reenable("codex.compat")

    assert_raise Mix.Error, ~r/invalid options: --bad/, fn ->
      capture_io(fn ->
        Compat.run(["--bad=value"])
      end)
    end
  end

  test "mix codex.compat raises when status returns error" do
    Application.put_env(:jido_codex, :stub_compat_status, fn _transport ->
      {:error, Jido.Codex.Error.config_error("bad compat", %{key: :compat})}
    end)

    Mix.Task.reenable("codex.compat")

    assert_raise Mix.Error, ~r/Codex compatibility check failed/, fn ->
      capture_io(fn ->
        Compat.run([])
      end)
    end
  end

  test "mix codex.smoke executes smoke run" do
    Mix.Task.reenable("codex.smoke")

    output =
      capture_io(fn ->
        Smoke.run(["Say hello", "--cwd", "/tmp/project", "--transport", "app_server", "--timeout", "3000"])
      end)

    assert_receive {:smoke_run, "Say hello", opts}
    assert opts[:cwd] == "/tmp/project"
    assert get_in(opts[:metadata], ["codex", "transport"]) == "app_server"
    assert get_in(opts[:metadata], ["codex", "turn_opts", "timeout_ms"]) == 3000
    assert output =~ "Smoke run completed"
  end

  test "mix codex.smoke validates prompt presence" do
    Mix.Task.reenable("codex.smoke")

    assert_raise Mix.Error, ~r/expected exactly one PROMPT/, fn ->
      capture_io(fn ->
        Smoke.run([])
      end)
    end
  end

  test "mix codex.smoke validates transport option" do
    Mix.Task.reenable("codex.smoke")

    assert_raise Mix.Error, ~r/invalid --transport value/, fn ->
      capture_io(fn ->
        Smoke.run(["hi", "--transport", "bad"])
      end)
    end
  end

  test "mix codex.smoke supports exec and app-server transport aliases" do
    Mix.Task.reenable("codex.smoke")

    capture_io(fn ->
      Smoke.run(["hello", "--transport", "exec"])
    end)

    assert_receive {:smoke_run, "hello", opts_exec}
    assert get_in(opts_exec[:metadata], ["codex", "transport"]) == "exec"

    Mix.Task.reenable("codex.smoke")

    capture_io(fn ->
      Smoke.run(["hello-2", "--transport", "app-server"])
    end)

    assert_receive {:smoke_run, "hello-2", opts_app_server}
    assert get_in(opts_app_server[:metadata], ["codex", "transport"]) == "app_server"
  end

  test "mix codex.smoke validates unknown options" do
    Mix.Task.reenable("codex.smoke")

    assert_raise Mix.Error, ~r/invalid options: --bad/, fn ->
      capture_io(fn ->
        Smoke.run(["hello", "--bad"])
      end)
    end

    Mix.Task.reenable("codex.smoke")

    assert_raise Mix.Error, ~r/invalid options: --bad/, fn ->
      capture_io(fn ->
        Smoke.run(["hello", "--bad=value"])
      end)
    end
  end

  test "mix codex.smoke raises on run failure" do
    Application.put_env(:jido_codex, :stub_public_codex_run, fn _prompt, _opts ->
      {:error, %{message: "boom"}}
    end)

    Mix.Task.reenable("codex.smoke")

    assert_raise Mix.Error, ~r/Codex smoke run failed: boom/, fn ->
      capture_io(fn ->
        Smoke.run(["hi"])
      end)
    end
  end

  test "mix codex.smoke formats non-map errors with inspect" do
    Application.put_env(:jido_codex, :stub_public_codex_run, fn _prompt, _opts ->
      {:error, :boom}
    end)

    Mix.Task.reenable("codex.smoke")

    assert_raise Mix.Error, ~r/Codex smoke run failed: :boom/, fn ->
      capture_io(fn ->
        Smoke.run(["hi"])
      end)
    end
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
