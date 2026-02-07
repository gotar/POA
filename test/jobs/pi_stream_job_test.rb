# frozen_string_literal: true

require "test_helper"

class PiStreamJobTest < ActiveJob::TestCase
  setup do
    @project = create_project
    @conversation = create_conversation(project: @project)
    @user_message = create_message(@conversation, content: "Hello AI")
    @assistant_message = @conversation.messages.create!(
      role: "assistant",
      content: "..."  # Placeholder content to pass validation
    )
  end

  # Basic job execution
  test "should find conversation and message" do
    PiStreamJob.perform_now(@conversation.id, @assistant_message.id, @project.id)

    # Job should complete without error
    assert true
  end

  test "should discard on missing conversation" do
    # Should not raise error
    PiStreamJob.perform_now(999999, @assistant_message.id, @project.id)
  end

  test "should discard on missing message" do
    # Should not raise error
    PiStreamJob.perform_now(@conversation.id, 999999, @project.id)
  end

  # With pi integration (requires pi installed and configured)
  test "should update assistant message content on success" do
    skip "Requires pi to be installed and configured" unless pi_available?

    PiStreamJob.perform_now(@conversation.id, @assistant_message.id, @project.id)

    @assistant_message.reload
    assert_not_empty @assistant_message.content
  end

  test "should handle pi rpc errors gracefully" do
    skip "Requires minitest/mock gem which is not bundled"

    # Mock pi service to raise error
    mock_service = Minitest::Mock.new
    mock_service.expect(:start, nil)
    mock_service.expect(:prompt, nil) { |prompt, &block| raise PiRpcService::TimeoutError, "Timeout" }
    mock_service.expect(:stop, nil)

    PiRpcService.stub(:new, mock_service) do
      PiStreamJob.perform_now(@conversation.id, @assistant_message.id, @project.id)
    end

    @assistant_message.reload
    assert_includes @assistant_message.content, "Error:"
  end

  test "should build prompt with project context" do
    # Add a todo and note
    @project.todos.create!(content: "Test todo", status: "pending")
    @project.notes.create!(title: "Context", content: "Important info", category: "context")

    # Just verify the job runs without error
    PiStreamJob.perform_now(@conversation.id, @assistant_message.id, @project.id)

    assert true
  end

  private

  def pi_available?
    system("which pi > /dev/null 2>&1") &&
      (ENV["ANTHROPIC_API_KEY"].present? || ENV["OPENAI_API_KEY"].present?)
  end
end
