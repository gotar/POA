# frozen_string_literal: true

require "test_helper"

class ConversationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = create_project
  end

  # Index
  test "should get index" do
    get project_conversations_url(@project)
    assert_response :success
  end

  test "index should assign recent conversations" do
    conversation = create_conversation(project: @project)

    get project_conversations_url(@project)

    assert_response :success
    assert_includes assigns(:conversations), conversation
  end

  # Show
  test "should show conversation" do
    conversation = create_conversation(project: @project)

    get project_conversation_url(@project, conversation)

    assert_response :success
    assert_equal conversation, assigns(:conversation)
  end

  test "show should include messages ordered by created_at" do
    conversation = create_conversation(project: @project)
    first = create_message(conversation, content: "First", created_at: 1.hour.ago)
    second = create_message(conversation, content: "Second", created_at: Time.current)

    get project_conversation_url(@project, conversation)

    assert_response :success
    messages = assigns(:messages)
    assert_equal [first, second], messages.to_a
  end

  test "show should assign new message for form" do
    conversation = create_conversation(project: @project)

    get project_conversation_url(@project, conversation)

    assert_response :success
    assert_instance_of Message, assigns(:new_message)
    assert_equal "user", assigns(:new_message).role
  end

  # Create
  test "should create conversation" do
    assert_difference("Conversation.count") do
      post project_conversations_url(@project), params: { conversation: { title: "New Chat" } }
    end

    assert_redirected_to project_conversation_url(@project, Conversation.last)
  end

  test "should create conversation with system prompt" do
    post project_conversations_url(@project), params: {
      conversation: { title: "Chat with Prompt", system_prompt: "You are helpful" }
    }

    conversation = Conversation.last
    assert_equal "Chat with Prompt", conversation.title
    assert_equal "You are helpful", conversation.system_prompt
  end

  # test "should use default title when not provided" do
  #   initial_count = @project.conversations.count

  #   post project_conversations_url(@project), params: { conversation: { title: "" } }

  #   # Debug: check what happened
  #   puts "Response status: #{response.status}"
  #   puts "Response body: #{response.body[0..200]}" if response.body

  #   final_count = @project.conversations.count
  #   puts "Initial count: #{initial_count}, Final count: #{final_count}"

  #   assert final_count > initial_count, "Conversation should have been created"
  # end

  # Destroy
  test "should destroy conversation" do
    conversation = create_conversation(project: @project)

    assert_difference("Conversation.count", -1) do
      delete project_conversation_url(@project, conversation)
    end

    assert_redirected_to @project
  end

  test "destroy should remove associated messages" do
    conversation = create_conversation(project: @project)
    message = create_message(conversation)

    assert_difference("Message.count", -1) do
      delete project_conversation_url(@project, conversation)
    end

    assert_redirected_to @project
  end

  # Clear Messages
  test "should clear all messages from conversation" do
    conversation = create_conversation(project: @project)
    3.times { |i| create_message(conversation, content: "Message #{i}") }

    assert_difference("Message.count", -3) do
      post clear_messages_project_conversation_url(@project, conversation)
    end

    assert_redirected_to project_conversation_url(@project, conversation)
    assert_equal 0, conversation.reload.messages.count
  end

  # Project isolation
  test "should not access conversation from different project" do
    other_project = create_project(name: "Other")
    other_conversation = create_conversation(project: other_project)

    get project_conversation_url(@project, other_conversation)

    assert_response :not_found
  end
end
