defmodule Jido.Codex.Test.StubsTest do
  use ExUnit.Case, async: false

  alias Jido.Codex.Test.{
    StubAdapter,
    StubAppServer,
    StubCLI,
    StubCodex,
    StubCodexOptions,
    StubCodexThread,
    StubCommand,
    StubCompatibility,
    StubMapper,
    StubPublicCodex,
    StubRunResultModule
  }

  setup do
    keys = [
      :stub_adapter_run,
      :stub_adapter_cancel,
      :stub_cli_resolve,
      :stub_command_run,
      :stub_compat_check,
      :stub_compat_status,
      :stub_codex_options_new,
      :stub_codex_options_path,
      :stub_codex_start_thread,
      :stub_codex_resume_thread,
      :stub_codex_run,
      :stub_codex_thread_run_streamed,
      :stub_run_result_events,
      :stub_run_result_cancel,
      :stub_app_server_connect,
      :stub_app_server_disconnect,
      :stub_mapper_map_event,
      :stub_public_codex_run
    ]

    saved = Map.new(keys, fn key -> {key, Application.get_env(:jido_codex, key)} end)

    on_exit(fn ->
      Enum.each(saved, fn {key, value} ->
        if is_nil(value),
          do: Application.delete_env(:jido_codex, key),
          else: Application.put_env(:jido_codex, key, value)
      end)
    end)

    :ok
  end

  test "stub modules delegate through env callbacks" do
    Application.put_env(:jido_codex, :stub_adapter_run, fn _request, _opts -> {:ok, [:ran]} end)
    Application.put_env(:jido_codex, :stub_adapter_cancel, fn _session_id -> :ok end)
    Application.put_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end)

    Application.put_env(:jido_codex, :stub_command_run, fn program, args, _opts ->
      {:ok, program <> Enum.join(args, "-")}
    end)

    Application.put_env(:jido_codex, :stub_compat_check, fn _transport -> :ok end)
    Application.put_env(:jido_codex, :stub_compat_status, fn transport -> {:ok, %{transport: transport}} end)

    Application.put_env(:jido_codex, :stub_codex_options_new, fn attrs -> {:ok, attrs} end)
    Application.put_env(:jido_codex, :stub_codex_options_path, fn -> {:ok, "/tmp/codex"} end)

    Application.put_env(:jido_codex, :stub_codex_start_thread, fn _co, _to -> {:ok, :thread} end)
    Application.put_env(:jido_codex, :stub_codex_resume_thread, fn _id, _co, _to -> {:ok, :thread} end)
    Application.put_env(:jido_codex, :stub_codex_run, fn _prompt, _opts -> {:ok, [:run]} end)

    Application.put_env(:jido_codex, :stub_codex_thread_run_streamed, fn _thread, _prompt, _opts ->
      {:ok, %{events: []}}
    end)

    Application.put_env(:jido_codex, :stub_run_result_events, fn rr -> rr.events end)
    Application.put_env(:jido_codex, :stub_run_result_cancel, fn _rr, _mode -> :ok end)

    Application.put_env(:jido_codex, :stub_app_server_connect, fn _co, _opts -> {:ok, self()} end)
    Application.put_env(:jido_codex, :stub_app_server_disconnect, fn _conn -> :ok end)
    Application.put_env(:jido_codex, :stub_mapper_map_event, fn _ev, _opts -> {:ok, [%{type: :mapped}]} end)
    Application.put_env(:jido_codex, :stub_public_codex_run, fn _prompt, _opts -> {:ok, []} end)

    assert {:ok, [:ran]} = StubAdapter.run(%{}, [])
    assert :ok = StubAdapter.cancel("s1")
    assert {:ok, %{program: "/tmp/codex"}} = StubCLI.resolve()
    assert {:ok, "/tmp/codex--help"} = StubCommand.run("/tmp/codex", ["--help"], [])
    assert :ok = StubCompatibility.check(:exec)
    assert {:ok, %{transport: :exec}} = StubCompatibility.status(:exec)

    assert {:ok, %{foo: :bar}} = StubCodexOptions.new(%{foo: :bar})
    assert {:ok, "/tmp/codex"} = StubCodexOptions.codex_path(%{})

    assert {:ok, :thread} = StubCodex.start_thread(%{}, %{})
    assert {:ok, :thread} = StubCodex.resume_thread("t1", %{}, %{})
    assert {:ok, [:run]} = StubCodex.run("hello", [])

    assert {:ok, %{events: []}} = StubCodexThread.run_streamed(%{}, "hello", %{})
    assert [] = StubRunResultModule.events(%{events: []})
    assert :ok = StubRunResultModule.cancel(%{}, :immediate)

    assert {:ok, _pid} = StubAppServer.connect(%{}, [])
    assert :ok = StubAppServer.disconnect(self())
    assert {:ok, [%{type: :mapped}]} = StubMapper.map_event(%{}, [])

    assert {:ok, []} = StubPublicCodex.run("hi", [])
  end

  test "stub modules provide sensible defaults when env callbacks are absent" do
    keys = [
      :stub_adapter_run,
      :stub_adapter_cancel,
      :stub_cli_resolve,
      :stub_command_run,
      :stub_compat_check,
      :stub_compat_status,
      :stub_codex_options_new,
      :stub_codex_options_path,
      :stub_codex_start_thread,
      :stub_codex_resume_thread,
      :stub_codex_run,
      :stub_codex_thread_run_streamed,
      :stub_run_result_events,
      :stub_run_result_cancel,
      :stub_app_server_connect,
      :stub_app_server_disconnect,
      :stub_mapper_map_event,
      :stub_public_codex_run
    ]

    Enum.each(keys, &Application.delete_env(:jido_codex, &1))

    assert {:ok, []} = StubAdapter.run(%{}, [])
    assert :ok = StubAdapter.cancel("s1")
    assert {:ok, %{program: "/tmp/codex"}} = StubCLI.resolve()
    assert {:ok, "ok"} = StubCommand.run("/tmp/codex", ["--help"], [])
    assert :ok = StubCompatibility.check(:exec)
    assert {:ok, %{transport: :exec}} = StubCompatibility.status(:exec)
    assert {:ok, %StubCodexOptions{}} = StubCodexOptions.new(%{})
    assert {:ok, "/tmp/codex"} = StubCodexOptions.codex_path(%{})
    assert {:ok, %{id: :thread}} = StubCodex.start_thread(%{}, %{})
    assert {:ok, %{id: :thread, resumed: true}} = StubCodex.resume_thread("t1", %{}, %{})
    assert {:ok, []} = StubCodex.run("hello", [])
    assert {:ok, %{events: []}} = StubCodexThread.run_streamed(%{}, "hello", %{})
    assert [] = StubRunResultModule.events(%{events: []})
    assert :ok = StubRunResultModule.cancel(%{}, :immediate)
    assert {:ok, _pid} = StubAppServer.connect(%{}, [])
    assert :ok = StubAppServer.disconnect(self())
    assert match?({:ok, [%Jido.Harness.Event{}]}, StubMapper.map_event(Jido.Codex.Test.Fixtures.turn_started(), []))
    assert {:ok, []} = StubPublicCodex.run("hi", [])
  end
end
