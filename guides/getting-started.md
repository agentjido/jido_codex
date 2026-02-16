# Getting Started with JidoCodex

JidoCodex is an adapter that wraps the Codex SDK to implement the JidoHarness.Adapter behaviour.

## Installation

Add `jido_codex` to your `mix.exs` dependencies:

```elixir
defp deps do
  [
    {:jido_codex, "~> 0.1"}
  ]
end
```

Then run:

```bash
mix deps.get
```

## Basic Usage

```elixir
# Run a prompt through Codex
{:ok, events} = JidoCodex.run("your prompt here")

# Events will be a stream of normalized JidoHarness.Event structs
```

## Adapter Implementation

JidoCodex.Adapter implements the `JidoHarness.Adapter` behaviour:

```elixir
defmodule JidoCodex.Adapter do
  @behaviour JidoHarness.Adapter

  def run(prompt, opts) do
    # Maps Codex SDK events to JidoHarness.Event structs
  end
end
```

## Next Steps

- Check `README.md` for more documentation
- Review `lib/jido_codex/` for the adapter implementation
- See `test/` for usage examples
