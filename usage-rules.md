# Jido.Codex Usage Rules for AI/LLM Development

## Scope

`jido_codex` is harness-first. Keep functionality focused on:
- implementing `Jido.Harness.Adapter`
- mapping Codex stream events into `Jido.Harness.Event`
- compatibility checks and minimal operational tasks

Avoid broad non-harness management wrappers.

## Module and Path Conventions

- Namespace: `Jido.Codex.*`
- Runtime code location: `lib/jido_codex/`
- Mix tasks location: `lib/mix/tasks/`

Primary files:
- `lib/jido_codex.ex`
- `lib/jido_codex/adapter.ex`
- `lib/jido_codex/mapper.ex`
- `lib/jido_codex/options.ex`
- `lib/jido_codex/compatibility.ex`
- `lib/jido_codex/session_registry.ex`

## Transport and Metadata Contract

Provider metadata lives under `RunRequest.metadata["codex"]`.

Supported keys:
- `"transport"`: `"exec"` | `"app_server"`
- `"thread_id"` / `"resume_last"`
- `"codex_opts"` / `"thread_opts"` / `"turn_opts"`
- `"app_server"` connect options
- `"cancel_mode"`: `"immediate"` | `"after_turn"`

Precedence:
- runtime adapter opts > metadata > defaults derived from `RunRequest`

## Event Mapping Rules

- Always emit normalized `%Jido.Harness.Event{}`.
- Use canonical types first (`:session_started`, `:output_text_delta`, `:session_completed`, etc.).
- Use `:codex_*` extensions for provider-specific semantics.
- Include `provider: :codex`, ISO-8601 timestamps, and raw passthrough.
- Unknown events must safely fall back to `:codex_event`.

## Error Handling

- Use `Jido.Codex.Error` helpers for structured errors.
- Validate/normalize input via `Jido.Codex.Options` (Zoi schema).
- Do not crash on unknown metadata fields or unknown Codex events.

## Testing Standards

- Keep `mix test` green with coverage >= 90%.
- Integration tests must be tagged `:integration` and excluded by default.
- Add unit coverage for mapper branches, option precedence, transport behavior, and cancellation paths.

## Quality Gates

Run before merging:

```bash
mix test
mix quality
```
