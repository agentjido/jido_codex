# Jido.Codex

`Jido.Codex` is the OpenAI Codex CLI adapter for [Jido.Harness](https://github.com/agentjido/jido_harness).

It provides:
- `Jido.Harness.Adapter` implementation (`Jido.Codex.Adapter`)
- normalized streaming event mapping (`Jido.Codex.Mapper`)
- exec transport (default) and app-server transport (opt-in)
- session cancellation by `session_id`
- compatibility/install/smoke mix tasks

## Installation

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

## Requirements

- Elixir `~> 1.18`
- Codex CLI installed and authenticated

## Quick Start

### 1) Validate local Codex setup

```bash
mix codex.install
mix codex.compat
mix codex.compat --transport app_server
```

### 2) Run a prompt

```elixir
{:ok, events} = Jido.Codex.run("Summarize this repository")

events
|> Enum.each(&IO.inspect/1)
```

### 3) Cancel an active session

```elixir
:ok = Jido.Codex.cancel("session-id-from-stream")
```

## Public API

- `Jido.Codex.run/2` - build a `Jido.Harness.RunRequest` from prompt + opts, then run
- `Jido.Codex.run_request/2` - run a pre-built `%Jido.Harness.RunRequest{}`
- `Jido.Codex.cancel/1` - cancel active run by session id
- `Jido.Codex.cli_installed?/0`
- `Jido.Codex.compatible?/1`
- `Jido.Codex.assert_compatible!/1`
- `Jido.Codex.version/0`

## Metadata Contract

`Jido.Codex.Adapter` reads provider-specific runtime controls from:

`request.metadata["codex"]`

Supported keys:

- `"transport"`: `"exec"` | `"app_server"` (default `"exec"`)
- `"thread_id"`: string
- `"resume_last"`: boolean
- `"codex_opts"`: map (passed to `Codex.Options.new/1`)
- `"thread_opts"`: map (passed to `Codex.start_thread/2` or `Codex.resume_thread/3`)
- `"turn_opts"`: map (passed to `Codex.Thread.run_streamed/3`)
- `"app_server"`: map (`init_timeout_ms`, `client_name`, `client_title`, `client_version`)
- `"cancel_mode"`: `"immediate"` | `"after_turn"` (default `"immediate"`)

Precedence:
- runtime adapter opts
- metadata (`metadata["codex"]`)
- defaults derived from `RunRequest`

Default mapping from `RunRequest`:
- `prompt` -> streamed turn input
- `cwd` -> `thread_opts.working_directory`
- `model` -> `thread_opts.model`
- `max_turns` -> `turn_opts.max_turns`
- `timeout_ms` -> `turn_opts.timeout_ms`
- `system_prompt` -> `thread_opts.developer_instructions`
- `attachments` -> `thread_opts.attachments`

## Event Mapping

Codex stream events are normalized to `Jido.Harness.Event` with:
- `provider: :codex`
- ISO-8601 `timestamp`
- raw event passthrough in `raw`

Canonical event types include:
- `:session_started`
- `:output_text_delta`
- `:output_text_final`
- `:thinking_delta`
- `:tool_call`
- `:tool_result`
- `:file_change`
- `:usage`
- `:session_completed`
- `:session_failed`
- `:session_cancelled`

Extended Codex-specific types use `:codex_*` naming (`:codex_turn_started`, `:codex_turn_plan_updated`, etc.).

## Mix Tasks

- `mix codex.install` - check Codex CLI discovery and print install help
- `mix codex.compat [--transport exec|app_server]` - run compatibility diagnostics
- `mix codex.smoke "PROMPT" [--cwd ... --transport ... --timeout ...]` - run minimal stream smoke test

## Development

```bash
mix test
mix quality
```

Integration tests are opt-in and excluded by default (`@tag :integration`).

## License

Apache-2.0. See [LICENSE](LICENSE).

## Package Purpose

`jido_codex` is the Codex CLI adapter for `jido_harness`, including Codex event mapping plus execution/session contract logic.

## Testing Paths

- Unit/contract tests: `mix test`
- Full quality gate: `mix quality`
- Optional live checks: `mix codex.install && mix codex.compat`
