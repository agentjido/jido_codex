# Changelog

## v0.1.0

- Hard rename to `Jido.Codex.*` modules
  - `Jido.Codex`
  - `Jido.Codex.Adapter`
  - `Jido.Codex.Mapper`
- Full `Jido.Harness.Adapter` implementation
  - `id/0`, `capabilities/0`, `run/2`, `cancel/1`
- Dual transport support
  - default `:exec`
  - opt-in `:app_server`
- Metadata-driven run contract via `RunRequest.metadata["codex"]`
- Session lifecycle + cancellation registry (`Jido.Codex.SessionRegistry`)
- Extended Codex event normalization (`Jido.Codex.Mapper`)
  - canonical event types + `:codex_*` extended types
- New runtime modules
  - `Jido.Codex.Options`
  - `Jido.Codex.Compatibility`
  - `Jido.Codex.Error`
  - `Jido.Codex.CLI`
  - `Jido.Codex.SystemCommand`
- New mix tasks
  - `mix codex.install`
  - `mix codex.compat`
  - `mix codex.smoke`
- Project parity hardening
  - config files (`config/*.exs`)
  - CI and release workflows
  - quality alias with warnings-as-errors
  - coverage threshold (90%)
- Test suite expansion
  - unit tests across adapter/mapper/options/compat/tasks/registry
  - integration tests tagged `:integration` and excluded by default
