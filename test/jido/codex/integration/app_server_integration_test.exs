defmodule Jido.Codex.Integration.AppServerTest do
  use ExUnit.Case

  alias Jido.Codex

  @moduletag :integration

  test "app-server transport returns result tuple" do
    result = Codex.run("Say hello", metadata: %{"codex" => %{"transport" => "app_server"}})
    assert match?({:ok, _}, result) or match?({:error, _}, result)
  end
end
