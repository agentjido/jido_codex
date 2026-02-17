defmodule Jido.Codex.SessionRegistry do
  @moduledoc """
  In-memory registry of active streamed Codex sessions used for cancellation.
  """

  @table __MODULE__

  @type session_entry :: %{
          required(:run_result) => term(),
          required(:run_result_module) => module(),
          required(:cancel_mode) => :immediate | :after_turn,
          optional(:app_server_connection) => pid() | nil
        }

  @doc "Registers an active session entry by session id."
  @spec register(String.t(), session_entry()) :: :ok
  def register(session_id, entry) when is_binary(session_id) and is_map(entry) do
    ensure_table!()
    :ets.insert(@table, {session_id, entry})
    :ok
  end

  @doc "Fetches a session entry by session id."
  @spec fetch(String.t()) :: {:ok, session_entry()} | {:error, :not_found}
  def fetch(session_id) when is_binary(session_id) do
    ensure_table!()

    case :ets.lookup(@table, session_id) do
      [{^session_id, entry}] -> {:ok, entry}
      [] -> {:error, :not_found}
    end
  end

  @doc "Deletes a session entry by session id."
  @spec delete(String.t()) :: :ok
  def delete(session_id) when is_binary(session_id) do
    ensure_table!()
    :ets.delete(@table, session_id)
    :ok
  end

  @doc "Clears all active session entries."
  @spec clear() :: :ok
  def clear do
    ensure_table!()
    :ets.delete_all_objects(@table)
    :ok
  end

  @doc "Lists all active session entries."
  @spec list() :: [{String.t(), session_entry()}]
  def list do
    ensure_table!()
    :ets.tab2list(@table)
  end

  defp ensure_table! do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:named_table, :public, :set, read_concurrency: true, write_concurrency: true])
        :ok

      _ ->
        :ok
    end
  rescue
    ArgumentError -> :ok
  end
end
