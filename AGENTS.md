# AGENTS.md — JidoCodex

## Overview

JidoCodex is a thin adapter wrapping the `codex_sdk` package to implement the `JidoHarness.Adapter` behaviour.

## Key Files

- `lib/jido_codex.ex` — Public API (`run/2`)
- `lib/jido_codex/adapter.ex` — `JidoHarness.Adapter` implementation
- `lib/jido_codex/mapper.ex` — Event mapping from Codex SDK to JidoHarness events

## Commands

- `mix test` — Run tests
- `mix quality` — Full quality check (compile, format, credo, dialyzer, doctor)

## Conventions

- Follow standard Elixir conventions
- Use `Logger` for output
- Keep the adapter thin — delegate to `codex_sdk` for heavy lifting
