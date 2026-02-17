defmodule Jido.Codex.Integration.RunTest do
  use ExUnit.Case

  alias Jido.Codex

  @moduletag :integration

  test "run returns result tuple" do
    result = Codex.run("Say hello")
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end
end
