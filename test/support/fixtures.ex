defmodule Jido.Codex.Test.Fixtures do
  @moduledoc false

  alias Codex.Events
  alias Codex.Items
  alias Codex.StreamEvent

  def run_item(event), do: %StreamEvent.RunItem{type: nil, event: event}

  def thread_started(session_id \\ "session-abc") do
    %Events.ThreadStarted{thread_id: session_id, metadata: %{}}
  end

  def session_configured(session_id \\ "session-abc") do
    %Events.SessionConfigured{session_id: session_id, cwd: "/tmp/project"}
  end

  def turn_started(session_id \\ "session-abc", turn_id \\ "turn-1") do
    %Events.TurnStarted{thread_id: session_id, turn_id: turn_id}
  end

  def turn_continuation(session_id \\ "session-abc", turn_id \\ "turn-1") do
    %Events.TurnContinuation{thread_id: session_id, turn_id: turn_id, continuation_token: "ctok", retryable: true}
  end

  def item_agent_message_delta(session_id \\ "session-abc") do
    %Events.ItemAgentMessageDelta{thread_id: session_id, turn_id: "turn-1", item: %{"delta" => "hello"}}
  end

  def item_completed_agent_message(session_id \\ "session-abc") do
    %Events.ItemCompleted{thread_id: session_id, turn_id: "turn-1", item: %Items.AgentMessage{text: "final"}}
  end

  def reasoning_delta(session_id \\ "session-abc") do
    %Events.ReasoningDelta{thread_id: session_id, turn_id: "turn-1", item_id: "item-1", delta: "thinking"}
  end

  def item_completed_reasoning(session_id \\ "session-abc") do
    item = %Items.Reasoning{text: "thinking", summary: ["summary"], content: ["content"]}
    %Events.ItemCompleted{thread_id: session_id, turn_id: "turn-1", item: item}
  end

  def tool_call_requested(session_id \\ "session-abc") do
    %Events.ToolCallRequested{
      thread_id: session_id,
      turn_id: "turn-1",
      call_id: "call-1",
      tool_name: "Read",
      arguments: %{"path" => "README.md"}
    }
  end

  def tool_call_completed(session_id \\ "session-abc") do
    %Events.ToolCallCompleted{
      thread_id: session_id,
      turn_id: "turn-1",
      call_id: "call-1",
      tool_name: "Read",
      output: %{"content" => "hello"}
    }
  end

  def item_completed_file_change(session_id \\ "session-abc") do
    item = %Items.FileChange{changes: [%{path: "lib/a.ex", kind: :update, diff: "@@"}], status: :completed}
    %Events.ItemCompleted{thread_id: session_id, turn_id: "turn-1", item: item}
  end

  def usage_updated(session_id \\ "session-abc") do
    %Events.ThreadTokenUsageUpdated{
      thread_id: session_id,
      turn_id: "turn-1",
      usage: %{"input_tokens" => 10},
      delta: %{"output_tokens" => 5}
    }
  end

  def rate_limits_updated(session_id \\ "session-abc") do
    %Events.AccountRateLimitsUpdated{thread_id: session_id, turn_id: "turn-1", rate_limits: %{"rpm" => 60}}
  end

  def turn_diff_updated(session_id \\ "session-abc") do
    %Events.TurnDiffUpdated{thread_id: session_id, turn_id: "turn-1", diff: "diff text"}
  end

  def turn_plan_updated(session_id \\ "session-abc") do
    %Events.TurnPlanUpdated{
      thread_id: session_id,
      turn_id: "turn-1",
      explanation: "why",
      plan: [%{step: "one", status: :pending}]
    }
  end

  def mcp_tool_progress(session_id \\ "session-abc") do
    %Events.McpToolCallProgress{thread_id: session_id, turn_id: "turn-1", item_id: "item-1", message: "progress"}
  end

  def request_user_input() do
    %Events.RequestUserInput{id: "req-1", turn_id: "turn-1", questions: [%{"question" => "Continue?"}]}
  end

  def config_warning() do
    %Events.ConfigWarning{summary: "warn", details: "details"}
  end

  def warning() do
    %Events.Warning{message: "warn message"}
  end

  def turn_completed(session_id \\ "session-abc") do
    %Events.TurnCompleted{
      thread_id: session_id,
      turn_id: "turn-1",
      status: "completed",
      response_id: "resp-1",
      usage: %{"input_tokens" => 1}
    }
  end

  def turn_failed(session_id \\ "session-abc") do
    %Events.TurnFailed{thread_id: session_id, turn_id: "turn-1", error: %{"message" => "failed"}}
  end

  def error_event(session_id \\ "session-abc") do
    %Events.Error{message: "boom", thread_id: session_id, turn_id: "turn-1"}
  end

  def turn_aborted() do
    %Events.TurnAborted{turn_id: "turn-1", reason: "cancelled"}
  end

  def unknown_event() do
    %Events.ContextCompacted{removed_turns: 1, remaining_turns: 2}
  end
end
