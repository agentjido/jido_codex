defmodule Jido.Codex.OptionsTest do
  use ExUnit.Case, async: true

  alias Jido.Codex.Options
  alias Jido.Harness.RunRequest

  test "from_run_request/2 maps request defaults" do
    request =
      Jido.Harness.RunRequest.new!(%{
        prompt: "hello",
        cwd: "/tmp/project",
        model: "gpt-5",
        max_turns: 4,
        timeout_ms: 12_000,
        system_prompt: "be concise",
        attachments: ["/tmp/a.txt"],
        metadata: %{}
      })

    assert {:ok, options} = Options.from_run_request(request)
    assert options.prompt == "hello"
    assert options.transport == :exec
    assert options.cancel_mode == :immediate
    assert options.thread_opts.working_directory == "/tmp/project"
    assert options.thread_opts.model == "gpt-5"
    assert options.thread_opts.developer_instructions == "be concise"
    assert options.turn_opts.max_turns == 4
    assert options.turn_opts.timeout_ms == 12_000
  end

  test "runtime opts override metadata and defaults" do
    request =
      Jido.Harness.RunRequest.new!(%{
        prompt: "hello",
        metadata: %{
          "codex" => %{
            "transport" => "app_server",
            "cancel_mode" => "after_turn",
            "thread_opts" => %{"model" => "metadata-model"},
            "turn_opts" => %{"max_turns" => 5}
          }
        }
      })

    assert {:ok, options} =
             Options.from_run_request(request,
               transport: :exec,
               cancel_mode: :immediate,
               thread_opts: %{model: "runtime-model"},
               turn_opts: %{max_turns: 9}
             )

    assert options.transport == :exec
    assert options.cancel_mode == :immediate
    assert options.thread_opts.model == "runtime-model"
    assert options.turn_opts.max_turns == 9
  end

  test "supports string top-level metadata key with atom nested keys" do
    request =
      Jido.Harness.RunRequest.new!(%{
        prompt: "hello",
        metadata: %{
          "codex" => %{
            transport: "app-server",
            cancel_mode: "after-turn",
            app_server: %{client_name: "jido"}
          }
        }
      })

    assert {:ok, options} = Options.from_run_request(request)
    assert options.transport == :app_server
    assert options.cancel_mode == :after_turn
    assert options.app_server.client_name == "jido"
  end

  test "deep merges nested option maps" do
    request =
      Jido.Harness.RunRequest.new!(%{
        prompt: "hello",
        metadata: %{
          "codex" => %{
            "thread_opts" => %{
              "config" => %{"a" => 1, "nested" => %{"x" => 1}}
            }
          }
        }
      })

    assert {:ok, options} =
             Options.from_run_request(request,
               thread_opts: %{"config" => %{"b" => 2, "nested" => %{"y" => 2}}}
             )

    assert options.thread_opts["config"]["a"] == 1
    assert options.thread_opts["config"]["b"] == 2
    assert options.thread_opts["config"]["nested"]["x"] == 1
    assert options.thread_opts["config"]["nested"]["y"] == 2
  end

  test "returns validation error for invalid transport" do
    request = Jido.Harness.RunRequest.new!(%{prompt: "hello", metadata: %{}})

    assert {:error, %Jido.Codex.Error.InvalidInputError{field: :transport}} =
             Options.from_run_request(request, transport: :bad)
  end

  test "returns validation error for invalid cancel mode" do
    request = Jido.Harness.RunRequest.new!(%{prompt: "hello", metadata: %{}})

    assert {:error, %Jido.Codex.Error.InvalidInputError{field: :cancel_mode}} =
             Options.from_run_request(request, cancel_mode: "never")
  end

  test "schema/new!/1 helpers validate attrs" do
    assert is_struct(Options.schema())

    assert %Options{} =
             Options.new!(%{
               prompt: "hello",
               transport: :exec,
               cancel_mode: :immediate
             })

    assert_raise ArgumentError, ~r/Invalid Jido.Codex.Options/, fn ->
      Options.new!(%{transport: :exec})
    end
  end

  test "handles non-map metadata and transport/cancel variants" do
    request = %RunRequest{
      prompt: "hello",
      cwd: nil,
      model: nil,
      max_turns: nil,
      timeout_ms: nil,
      system_prompt: nil,
      allowed_tools: nil,
      attachments: [],
      metadata: :invalid
    }

    assert {:ok, options} = Options.from_run_request(request, transport: :app_server, cancel_mode: :after_turn)
    assert options.transport == :app_server
    assert options.cancel_mode == :after_turn

    request2 = %{request | metadata: %{"codex" => %{"transport" => "exec", "cancel_mode" => "after_turn"}}}
    assert {:ok, options2} = Options.from_run_request(request2, cancel_mode: "immediate")
    assert options2.transport == :exec
    assert options2.cancel_mode == :immediate

    assert {:ok, options3} = Options.from_run_request(request2)
    assert options3.cancel_mode == :after_turn
  end
end
