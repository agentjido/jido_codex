defmodule Jido.Codex.Options do
  @moduledoc """
  Runtime option normalization for Codex adapter execution.

  Combines:
  - defaults derived from `%Jido.Harness.RunRequest{}`
  - `request.metadata["codex"]` overrides
  - runtime adapter opts overrides

  Precedence is runtime opts > metadata > defaults.
  """

  alias Jido.Codex.Error
  alias Jido.Harness.RunRequest

  @schema Zoi.struct(
            __MODULE__,
            %{
              prompt: Zoi.string(),
              transport: Zoi.any() |> Zoi.optional(),
              thread_id: Zoi.string() |> Zoi.nullable() |> Zoi.optional(),
              resume_last: Zoi.boolean() |> Zoi.optional(),
              codex_opts: Zoi.map() |> Zoi.optional(),
              thread_opts: Zoi.map() |> Zoi.optional(),
              turn_opts: Zoi.map() |> Zoi.optional(),
              app_server: Zoi.map() |> Zoi.optional(),
              cancel_mode: Zoi.any() |> Zoi.optional()
            },
            coerce: true
          )

  @type t :: unquote(Zoi.type_spec(@schema))

  @enforce_keys Zoi.Struct.enforce_keys(@schema)
  defstruct Zoi.Struct.struct_fields(@schema)

  @doc "Returns the Zoi schema for adapter options."
  @spec schema() :: Zoi.schema()
  def schema, do: @schema

  @doc "Validates normalized adapter option attributes."
  @spec new(map()) :: {:ok, t()} | {:error, term()}
  def new(attrs) when is_map(attrs), do: Zoi.parse(@schema, attrs)

  @doc "Like `new/1` but raises on validation errors."
  @spec new!(map()) :: t()
  def new!(attrs) do
    case new(attrs) do
      {:ok, value} -> value
      {:error, reason} -> raise ArgumentError, "Invalid #{inspect(__MODULE__)}: #{inspect(reason)}"
    end
  end

  @doc "Builds normalized adapter options from a run request and runtime options."
  @spec from_run_request(RunRequest.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_run_request(%RunRequest{} = request, runtime_opts \\ []) when is_list(runtime_opts) do
    metadata_codex = codex_metadata(request.metadata)
    runtime_map = Map.new(runtime_opts)

    defaults = request_defaults(request)

    attrs = %{
      prompt: request.prompt,
      transport: resolve_scalar(runtime_map, metadata_codex, :transport, defaults.transport),
      thread_id: resolve_scalar(runtime_map, metadata_codex, :thread_id, defaults.thread_id),
      resume_last: resolve_scalar(runtime_map, metadata_codex, :resume_last, defaults.resume_last),
      codex_opts: merge_maps(defaults.codex_opts, metadata_codex, runtime_map, :codex_opts),
      thread_opts: merge_maps(defaults.thread_opts, metadata_codex, runtime_map, :thread_opts),
      turn_opts: merge_maps(defaults.turn_opts, metadata_codex, runtime_map, :turn_opts),
      app_server: merge_maps(defaults.app_server, metadata_codex, runtime_map, :app_server),
      cancel_mode: resolve_scalar(runtime_map, metadata_codex, :cancel_mode, defaults.cancel_mode)
    }

    with {:ok, parsed} <- new(attrs),
         {:ok, transport} <- normalize_transport(parsed.transport),
         {:ok, cancel_mode} <- normalize_cancel_mode(parsed.cancel_mode) do
      {:ok,
       %{
         parsed
         | transport: transport,
           cancel_mode: cancel_mode,
           codex_opts: sanitize_map(parsed.codex_opts),
           thread_opts: sanitize_map(parsed.thread_opts),
           turn_opts: sanitize_map(parsed.turn_opts),
           app_server: sanitize_map(parsed.app_server)
       }}
    end
  end

  defp request_defaults(%RunRequest{} = request) do
    %{
      transport: :exec,
      thread_id: nil,
      resume_last: false,
      cancel_mode: :immediate,
      codex_opts: %{},
      thread_opts:
        %{}
        |> maybe_put(:working_directory, request.cwd)
        |> maybe_put(:model, request.model)
        |> maybe_put(:developer_instructions, request.system_prompt)
        |> maybe_put(:attachments, request.attachments),
      turn_opts:
        %{}
        |> maybe_put(:max_turns, request.max_turns)
        |> maybe_put(:timeout_ms, request.timeout_ms),
      app_server: %{}
    }
  end

  defp codex_metadata(metadata) when is_map(metadata) do
    metadata
    |> fetch_value(:codex)
    |> sanitize_map()
  end

  defp codex_metadata(_), do: %{}

  defp resolve_scalar(runtime_map, metadata_codex, key, default) do
    case fetch_value(runtime_map, key) do
      nil ->
        case fetch_value(metadata_codex, key) do
          nil -> default
          value -> value
        end

      value ->
        value
    end
  end

  defp merge_maps(base, metadata_codex, runtime_map, key) do
    base
    |> deep_merge(sanitize_map(fetch_value(metadata_codex, key)))
    |> deep_merge(sanitize_map(fetch_value(runtime_map, key)))
  end

  defp normalize_transport(:exec), do: {:ok, :exec}
  defp normalize_transport(:app_server), do: {:ok, :app_server}
  defp normalize_transport("exec"), do: {:ok, :exec}
  defp normalize_transport("app_server"), do: {:ok, :app_server}
  defp normalize_transport("app-server"), do: {:ok, :app_server}

  defp normalize_transport(value) do
    {:error, Error.validation_error("Invalid Codex transport", %{field: :transport, value: value})}
  end

  defp normalize_cancel_mode(:immediate), do: {:ok, :immediate}
  defp normalize_cancel_mode(:after_turn), do: {:ok, :after_turn}
  defp normalize_cancel_mode("immediate"), do: {:ok, :immediate}
  defp normalize_cancel_mode("after_turn"), do: {:ok, :after_turn}
  defp normalize_cancel_mode("after-turn"), do: {:ok, :after_turn}

  defp normalize_cancel_mode(value) do
    {:error, Error.validation_error("Invalid cancel mode", %{field: :cancel_mode, value: value})}
  end

  defp fetch_value(map, key) do
    atom_value = Map.get(map, key)

    if is_nil(atom_value) do
      Map.get(map, Atom.to_string(key))
    else
      atom_value
    end
  end

  defp sanitize_map(value) when is_map(value), do: value
  defp sanitize_map(_), do: %{}

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, lhs, rhs ->
      if is_map(lhs) and is_map(rhs), do: deep_merge(lhs, rhs), else: rhs
    end)
  end

  defp deep_merge(_left, right), do: right

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
