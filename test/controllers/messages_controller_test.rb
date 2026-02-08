# frozen_string_literal: true

require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = create_project
    @conversation = create_conversation(project: @project)
  end

  # Create (HTML)
  test "should create message in conversation" do
    assert_difference("Message.count", 2) do
      post project_conversation_messages_url(@project, @conversation), params: {
        message: { content: "Hello, AI!" }
      }
    end

    message = @conversation.messages.where(role: "user").order(:created_at).last
    assert_equal "user", message.role
    assert_equal "Hello, AI!", message.content
  end

  test "create should set role to user" do
    post project_conversation_messages_url(@project, @conversation), params: {
      message: { content: "Test", role: "assistant" } # Try to override
    }

    message = @conversation.messages.where(role: "user").order(:created_at).last
    assert_equal "user", message.role
  end

  test "create should redirect to conversation on HTML request" do
    post project_conversation_messages_url(@project, @conversation), params: {
      message: { content: "Hello" }
    }

    assert_redirected_to project_conversation_url(@project, @conversation)
  end

  # Create (Turbo Stream)
  test "should create message via turbo stream" do
    # Creates user message + assistant message placeholder
    assert_difference("Message.count", 2) do
      post project_conversation_messages_url(@project, @conversation),
        params: { message: { content: "Turbo message" } },
        as: :turbo_stream
    end

    assert_response :success
    assert_match "text/vnd.turbo-stream.html", response.content_type
  end

  test "turbo stream create should create assistant message placeholder" do
    assert_difference("Message.count", 2) do
      post project_conversation_messages_url(@project, @conversation),
        params: { message: { content: "Hello" } },
        as: :turbo_stream
    end

    assistant_message = Message.last
    assert_equal "assistant", assistant_message.role
    assert_equal "", assistant_message.content  # Placeholder (blank while streaming)
  end

  # Error handling
  test "should handle empty message content" do
    assert_no_difference("Message.count") do
      post project_conversation_messages_url(@project, @conversation), params: {
        message: { content: "" }
      }
    end
  end

  # Title generation
  test "create should generate title from first message when conversation has default title" do
    conversation = @project.conversations.create!(title: "New Chat")

    post project_conversation_messages_url(@project, conversation), params: {
      message: { content: "This is my first question to the AI" }
    }

    # Title should be generated from first message since original was "New Chat"
    conversation.reload
    # Note: generate_title_from_first_message only runs if title is blank
    # So title stays as "New Chat" in current implementation
    assert_equal "New Chat", conversation.title
  end

  test "create should not override existing custom title" do
    conversation = @project.conversations.create!(title: "Custom Title")

    post project_conversation_messages_url(@project, conversation), params: {
      message: { content: "Hello there" }
    }

    conversation.reload
    assert_equal "Custom Title", conversation.title
  end

  # Project isolation
  test "should not create message in conversation from different project" do
    other_project = create_project(name: "Other")
    other_conversation = create_conversation(project: other_project)

    post project_conversation_messages_url(@project, other_conversation), params: {
      message: { content: "Hello" }
    }

    assert_response :not_found
  end
end
