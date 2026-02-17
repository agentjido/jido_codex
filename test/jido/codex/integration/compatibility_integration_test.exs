defmodule Jido.Codex.Integration.CompatibilityTest do
  use ExUnit.Case

  alias Jido.Codex.Compatibility

  @moduletag :integration

  test "compatibility checks run against local environment" do
    result = Compatibility.check(:exec)
    assert result == :ok or match?({:error, _}, result)
  end
end
