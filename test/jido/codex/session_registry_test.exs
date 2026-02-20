defmodule Jido.Codex.SessionRegistryTest do
  use ExUnit.Case, async: false

  alias Jido.Codex.SessionRegistry

  setup do
    SessionRegistry.clear()
    :ok
  end

  test "registers and fetches entries" do
    assert :ok = SessionRegistry.register("s1", %{run_result: :rr, run_result_module: Mod, cancel_mode: :immediate})
    assert {:ok, entry} = SessionRegistry.fetch("s1")
    assert entry.cancel_mode == :immediate
  end

  test "returns not_found for unknown sessions" do
    assert {:error, :not_found} = SessionRegistry.fetch("missing")
  end

  test "deletes entries" do
    SessionRegistry.register("s1", %{run_result: :rr, run_result_module: Mod, cancel_mode: :immediate})
    assert :ok = SessionRegistry.delete("s1")
    assert {:error, :not_found} = SessionRegistry.fetch("s1")
  end

  test "clear removes all entries" do
    SessionRegistry.register("a", %{run_result: :rr, run_result_module: Mod, cancel_mode: :immediate})
    SessionRegistry.register("b", %{run_result: :rr, run_result_module: Mod, cancel_mode: :immediate})
    assert length(SessionRegistry.list()) == 2
    SessionRegistry.clear()
    assert SessionRegistry.list() == []
  end

  test "removes sessions when owner process exits" do
    owner =
      spawn(fn ->
        receive do
          :stop -> :ok
        end
      end)

    SessionRegistry.register(
      "owned-session",
      %{run_result: :rr, run_result_module: Mod, cancel_mode: :immediate},
      owner: owner
    )

    assert {:ok, _entry} = SessionRegistry.fetch("owned-session")
    send(owner, :stop)
    wait_until(fn -> match?({:error, :not_found}, SessionRegistry.fetch("owned-session")) end)
  end

  defp wait_until(fun, attempts \\ 20)

  defp wait_until(_fun, 0), do: flunk("condition not met")

  defp wait_until(fun, attempts) do
    if fun.() do
      :ok
    else
      Process.sleep(10)
      wait_until(fun, attempts - 1)
    end
  end
end
