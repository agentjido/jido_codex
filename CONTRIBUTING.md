# Contributing to Jido.Codex

## Development Setup

1. Clone the repo.
2. Install deps:

```bash
mix setup
```

3. Run tests:

```bash
mix test
```

4. Run quality checks:

```bash
mix quality
```

## Contribution Standards

- Target Elixir `~> 1.18`.
- Keep adapter behavior aligned with `Jido.Harness.Adapter`.
- Use Zoi for validation and Splode-style structured errors.
- Add or update tests for all behavior changes.
- Keep coverage at or above the configured threshold (90%).
- Use conventional commits (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`).

## Project Layout

- `lib/jido_codex/codex.ex` - public API facade
- `lib/jido_codex/adapter.ex` - adapter implementation
- `lib/jido_codex/mapper.ex` - Codex -> `Jido.Harness.Event` mapping
- `lib/jido_codex/options.ex` - metadata/runtime option normalization
- `lib/jido_codex/compatibility.ex` - CLI compatibility checks
- `lib/mix/tasks/` - `codex.install`, `codex.compat`, `codex.smoke`

## Integration Tests

Integration tests are tagged `:integration` and excluded by default.

Run them explicitly when Codex CLI and auth are available:

```bash
mix test --include integration
```

## License

By contributing, you agree contributions are licensed under Apache-2.0.
