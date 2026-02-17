# Getting Started with Jido.Codex

This guide covers the main flows for `jido_codex`:
- setup and compatibility checks
- running prompts with exec and app-server transports
- resume/cancel behavior
- smoke validation and tests

## 1) Install

```elixir
defp deps do
  [
    {:jido_harness, "~> 0.1"},
    {:jido_codex, "~> 0.1"}
  ]
end
```

Then:

```bash
mix deps.get
```

## 2) Verify Codex CLI

```bash
mix codex.install
mix codex.compat
mix codex.compat --transport app_server
```

## 3) Run a Prompt (Default Exec Transport)

```elixir
{:ok, stream} = Jido.Codex.run("Review failing tests and propose a fix")

stream
|> Enum.each(&IO.inspect/1)
```

The stream contains normalized `%Jido.Harness.Event{}` entries.

## 4) Use App-Server Transport

```elixir
{:ok, stream} =
  Jido.Codex.run("Summarize recent file changes",
    metadata: %{
      "codex" => %{
        "transport" => "app_server",
        "app_server" => %{
          "client_name" => "jido",
          "client_title" => "Jido Codex Adapter",
          "client_version" => Jido.Codex.version()
        }
      }
    }
  )
```

## 5) Resume Existing Work

Resume explicit thread:

```elixir
{:ok, stream} =
  Jido.Codex.run("Continue from prior context",
    metadata: %{"codex" => %{"thread_id" => "thread_123"}}
  )
```

Resume latest thread:

```elixir
{:ok, stream} =
  Jido.Codex.run("Continue latest work",
    metadata: %{"codex" => %{"resume_last" => true}}
  )
```

## 6) Cancel an Active Session

```elixir
:ok = Jido.Codex.cancel("session-id")
```

Session ids are emitted in `:session_started` payloads.

## 7) Use `run_request/2` Directly

```elixir
request =
  Jido.Harness.RunRequest.new!(%{
    prompt: "Explain this module",
    cwd: "/repo",
    model: "gpt-5",
    metadata: %{"codex" => %{"transport" => "exec"}}
  })

{:ok, stream} = Jido.Codex.run_request(request)
```

## 8) Smoke Test

```bash
mix codex.smoke "Say hello"
mix codex.smoke "Inspect this repo" --cwd /path/to/repo --transport app_server --timeout 30000
```

## 9) Run Tests and Quality

```bash
mix test
mix quality
```

Integration tests are opt-in (`@tag :integration`) and excluded by default.
