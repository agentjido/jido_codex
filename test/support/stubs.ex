defmodule Jido.Codex.Test.StubAdapter do
  @moduledoc false

  def run(request, opts) do
    Application.get_env(:jido_codex, :stub_adapter_run, fn _request, _opts -> {:ok, []} end).(request, opts)
  end

  def cancel(session_id) do
    Application.get_env(:jido_codex, :stub_adapter_cancel, fn _session_id -> :ok end).(session_id)
  end
end

defmodule Jido.Codex.Test.StubCLI do
  @moduledoc false

  def resolve do
    Application.get_env(:jido_codex, :stub_cli_resolve, fn -> {:ok, %{program: "/tmp/codex"}} end).()
  end
end

defmodule Jido.Codex.Test.StubCommand do
  @moduledoc false

  def run(program, args, opts \\ []) do
    Application.get_env(:jido_codex, :stub_command_run, fn _program, _args, _opts -> {:ok, "ok"} end).(
      program,
      args,
      opts
    )
  end
end

defmodule Jido.Codex.Test.StubCompatibility do
  @moduledoc false

  def check(transport \\ :exec) do
    Application.get_env(:jido_codex, :stub_compat_check, fn _transport -> :ok end).(transport)
  end

  def status(transport \\ :exec) do
    Application.get_env(:jido_codex, :stub_compat_status, fn tr ->
      {:ok, %{program: "/tmp/codex", version: "0.10.1", transport: tr, required_tokens: ["exec"]}}
    end).(transport)
  end
end

defmodule Jido.Codex.Test.StubCodexOptions do
  @moduledoc false

  defstruct [:path]

  def new(attrs \\ %{}) do
    Application.get_env(:jido_codex, :stub_codex_options_new, fn options -> {:ok, struct(__MODULE__, options)} end).(
      attrs
    )
  end

  def codex_path(_options) do
    Application.get_env(:jido_codex, :stub_codex_options_path, fn -> {:ok, "/tmp/codex"} end).()
  end
end

defmodule Jido.Codex.Test.StubCodex do
  @moduledoc false

  def start_thread(codex_opts, thread_opts) do
    Application.get_env(:jido_codex, :stub_codex_start_thread, fn _codex_opts, _thread_opts -> {:ok, %{id: :thread}} end).(
      codex_opts,
      thread_opts
    )
  end

  def resume_thread(thread_id, codex_opts, thread_opts) do
    Application.get_env(:jido_codex, :stub_codex_resume_thread, fn _thread_id, _codex_opts, _thread_opts ->
      {:ok, %{id: :thread, resumed: true}}
    end).(thread_id, codex_opts, thread_opts)
  end

  def run(prompt, opts) do
    Application.get_env(:jido_codex, :stub_codex_run, fn _prompt, _opts -> {:ok, []} end).(prompt, opts)
  end
end

defmodule Jido.Codex.Test.StubCodexThread do
  @moduledoc false

  def run_streamed(thread, prompt, turn_opts) do
    Application.get_env(:jido_codex, :stub_codex_thread_run_streamed, fn _thread, _prompt, _turn_opts ->
      {:ok, %{events: []}}
    end).(thread, prompt, turn_opts)
  end
end

defmodule Jido.Codex.Test.StubRunResultModule do
  @moduledoc false

  def events(run_result) do
    Application.get_env(:jido_codex, :stub_run_result_events, fn rr -> rr.events end).(run_result)
  end

  def cancel(run_result, mode) do
    Application.get_env(:jido_codex, :stub_run_result_cancel, fn _run_result, _mode -> :ok end).(run_result, mode)
  end
end

defmodule Jido.Codex.Test.StubAppServer do
  @moduledoc false

  def connect(codex_opts, opts) do
    Application.get_env(:jido_codex, :stub_app_server_connect, fn _codex_opts, _opts -> {:ok, self()} end).(
      codex_opts,
      opts
    )
  end

  def disconnect(connection) do
    Application.get_env(:jido_codex, :stub_app_server_disconnect, fn _connection -> :ok end).(connection)
  end
end

defmodule Jido.Codex.Test.StubMapper do
  @moduledoc false

  def map_event(event, opts \\ []) do
    Application.get_env(:jido_codex, :stub_mapper_map_event, fn ev, _opts -> Jido.Codex.Mapper.map_event(ev, []) end).(
      event,
      opts
    )
  end
end

defmodule Jido.Codex.Test.StubPublicCodex do
  @moduledoc false

  def run(prompt, opts) do
    Application.get_env(:jido_codex, :stub_public_codex_run, fn _prompt, _opts -> {:ok, []} end).(prompt, opts)
  end
end
