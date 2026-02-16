# JidoCodex Usage Rules for AI/LLM Development

## Context

JidoCodex is a thin adapter wrapping the Codex SDK to implement the JidoHarness.Adapter behaviour.

## Key Concepts

### Adapter Pattern
- `JidoCodex.Adapter` implements `JidoHarness.Adapter` behaviour
- `JidoCodex.Mapper` translates Codex SDK events to normalized `JidoHarness.Event` structs
- Keep the adapter thin — delegate to `codex_sdk` for heavy lifting

### Error Handling
- All errors use `Splode` error composition (when implemented)
- Validation errors use `JidoCodex.Error.InvalidInputError`
- Execution errors use `JidoCodex.Error.ExecutionFailureError`

### Schema Validation
- Core structs use Zoi schemas
- Use `new/1` and `new!/1` for struct construction with validation
- Validation logic stays in schemas, not scattered in functions

## Development Guidelines

### Adding Modules
1. Create under `lib/jido_codex/`
2. Add `@moduledoc` with clear description
3. Define Zoi schema for any structs
4. Document all public functions with `@doc` and `@spec`
5. Create tests in `test/jido_codex/`

### Testing
```bash
mix test --cover        # Run tests with coverage
mix quality             # Full quality checks
```

### Common Commands
```bash
mix setup               # Setup environment
mix test                # Run tests
mix quality             # Lint, format, dialyzer, doctor
mix docs                # Generate documentation
mix doctor --raise      # Check doc coverage
```

## Git Workflow

Use conventional commits:
```bash
git commit -m "feat(mapper): add event translation for X"
git commit -m "fix(adapter): handle error case in Y"
git commit -m "docs: clarify usage of Z"
```

Valid commit types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

## Code Standards

- Line length: 120 characters
- No `IO.puts` — use `Logger` for output
- All public functions need `@doc` and `@spec`
- No `jido_dep/4` helper functions
- Tests must have >90% coverage

## Integration Points

### Codex SDK
- Wraps `CodexSdk.execute/2` for running prompts
- Maps SDK response events to `JidoHarness.Event` structs

### JidoHarness
- Implements `JidoHarness.Adapter` behaviour
- Events comply with `JidoHarness.Event` schema

## Questions?

- Review `AGENTS.md` for project-specific instructions
- Check `GENERIC_PACKAGE_QA.md` for ecosystem standards
- Look at `jido_amp` or `jido_claude` for adapter patterns
