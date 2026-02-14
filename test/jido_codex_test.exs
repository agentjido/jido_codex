defmodule JidoCodexTest do
  use ExUnit.Case, async: true

  test "adapter id returns :codex" do
    assert JidoCodex.Adapter.id() == :codex
  end

  test "adapter capabilities returns a map" do
    caps = JidoCodex.Adapter.capabilities()
    assert is_map(caps)
    assert caps.streaming? == true
    assert caps.thinking? == false
  end

  test "run/1 returns not yet implemented error" do
    assert {:error, "not yet implemented"} = JidoCodex.run("hello")
  end
end
