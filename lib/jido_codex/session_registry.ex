defmodule Jido.Codex.SessionRegistry do
  @moduledoc """
  In-memory registry of active streamed Codex sessions used for cancellation.

  The registry is process-owned and tracks session owner pids to guarantee
  cleanup if a stream owner crashes before explicit teardown runs.
  """

  use GenServer

  @name __MODULE__

  @type session_entry :: %{
          required(:run_result) => term(),
          required(:run_result_module) => module(),
          required(:cancel_mode) => :immediate | :after_turn,
          optional(:app_server_connection) => pid() | nil
        }

  @type register_opt :: {:owner, pid()}

  @doc "Registers an active session entry by session id."
  @spec register(String.t(), session_entry(), [register_opt()]) :: :ok
  def register(session_id, entry, opts \\ []) when is_binary(session_id) and is_map(entry) and is_list(opts) do
    ensure_started!()
    owner = opts[:owner] || self()
    GenServer.call(@name, {:register, session_id, entry, owner})
  end

  @doc "Fetches a session entry by session id."
  @spec fetch(String.t()) :: {:ok, session_entry()} | {:error, :not_found}
  def fetch(session_id) when is_binary(session_id) do
    ensure_started!()
    GenServer.call(@name, {:fetch, session_id})
  end

  @doc "Deletes a session entry by session id."
  @spec delete(String.t()) :: :ok
  def delete(session_id) when is_binary(session_id) do
    ensure_started!()
    GenServer.call(@name, {:delete, session_id})
  end

  @doc "Clears all active session entries."
  @spec clear() :: :ok
  def clear do
    ensure_started!()
    GenServer.call(@name, :clear)
  end

  @doc "Lists all active session entries."
  @spec list() :: [{String.t(), session_entry()}]
  def list do
    ensure_started!()
    GenServer.call(@name, :list)
  end

  @impl true
  def init(:ok) do
    {:ok, %{sessions: %{}, owners: %{}, monitors: %{}}}
  end

  @impl true
  def handle_call({:register, session_id, entry, owner}, _from, state) do
    state =
      state
      |> remove_session(session_id)
      |> ensure_owner_monitor(owner)
      |> put_session(session_id, entry, owner)

    {:reply, :ok, state}
  end

  def handle_call({:fetch, session_id}, _from, state) do
    reply =
      case Map.fetch(state.sessions, session_id) do
        {:ok, %{entry: entry}} -> {:ok, entry}
        :error -> {:error, :not_found}
      end

    {:reply, reply, state}
  end

  def handle_call({:delete, session_id}, _from, state) do
    {:reply, :ok, remove_session(state, session_id)}
  end

  def handle_call(:clear, _from, state) do
    Enum.each(state.monitors, fn {_owner, ref} ->
      Process.demonitor(ref, [:flush])
    end)

    {:reply, :ok, %{sessions: %{}, owners: %{}, monitors: %{}}}
  end

  def handle_call(:list, _from, state) do
    items =
      state.sessions
      |> Enum.map(fn {session_id, %{entry: entry}} -> {session_id, entry} end)

    {:reply, items, state}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, owner, _reason}, state) do
    case state.monitors do
      %{^owner => ^ref} ->
        {:noreply, remove_owner(state, owner)}

      _ ->
        {:noreply, state}
    end
  end

  defp put_session(state, session_id, entry, owner) do
    sessions = Map.put(state.sessions, session_id, %{entry: entry, owner: owner})
    owners = Map.update(state.owners, owner, MapSet.new([session_id]), &MapSet.put(&1, session_id))
    %{state | sessions: sessions, owners: owners}
  end

  defp remove_owner(state, owner) do
    session_ids = state.owners |> Map.get(owner, MapSet.new()) |> MapSet.to_list()

    sessions = Enum.reduce(session_ids, state.sessions, &Map.delete(&2, &1))
    owners = Map.delete(state.owners, owner)
    monitors = Map.delete(state.monitors, owner)

    %{state | sessions: sessions, owners: owners, monitors: monitors}
  end

  defp remove_session(state, session_id) do
    case Map.pop(state.sessions, session_id) do
      {nil, _sessions} ->
        state

      {%{owner: owner}, sessions} ->
        owners =
          state.owners
          |> Map.get(owner, MapSet.new())
          |> MapSet.delete(session_id)
          |> then(fn set ->
            if MapSet.size(set) == 0 do
              Map.delete(state.owners, owner)
            else
              Map.put(state.owners, owner, set)
            end
          end)

        monitors =
          case Map.has_key?(owners, owner) do
            true ->
              state.monitors

            false ->
              case Map.pop(state.monitors, owner) do
                {nil, rest} ->
                  rest

                {ref, rest} ->
                  Process.demonitor(ref, [:flush])
                  rest
              end
          end

        %{state | sessions: sessions, owners: owners, monitors: monitors}
    end
  end

  defp ensure_owner_monitor(state, owner) do
    if Map.has_key?(state.monitors, owner) do
      state
    else
      ref = Process.monitor(owner)
      %{state | monitors: Map.put(state.monitors, owner, ref)}
    end
  end

  defp ensure_started! do
    case Process.whereis(@name) do
      nil ->
        case GenServer.start(__MODULE__, :ok, name: @name) do
          {:ok, _pid} -> :ok
          {:error, {:already_started, _pid}} -> :ok
          {:error, reason} -> raise "unable to start #{inspect(@name)}: #{inspect(reason)}"
        end

      _pid ->
        :ok
    end
  end
end
