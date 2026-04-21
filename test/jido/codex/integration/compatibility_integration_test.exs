defmodule Jido.Codex.Integration.CompatibilityTest do
  use ExUnit.Case
  use Jido.Codex.LiveIntegrationCase

  alias Jido.Codex.Compatibility

  @integration_skip_reason Jido.Codex.LiveIntegrationCase.skip_reason()

  if @integration_skip_reason do
    @moduletag skip: @integration_skip_reason
  end

  test "compatibility checks pass against the live CLI" do
    assert :ok = Compatibility.check(:exec)
  end
end
