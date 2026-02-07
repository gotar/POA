# frozen_string_literal: true

require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  setup do
    @project = create_project
  end

  # Validations
  test "should be valid with title and project" do
    conversation = Conversation.new(title: "Test Chat", project: @project)
    assert conversation.valid?
  end

  test "should be invalid without title" do
    conversation = Conversation.new(title: nil, project: @project)
    assert_not conversation.valid?
    assert_includes conversation.errors[:title], "can't be blank"
  end

  test "should require project" do
    conversation = Conversation.new(title: "Test", project: nil)
    assert_not conversation.valid?
  end

  test "title should not exceed 255 characters" do
    conversation = Conversation.new(title: "x" * 256, project: @project)
    assert_not conversation.valid?
  end

  # Associations
  test "should belong to project" do
    conversation = Conversation.new
    assert_respond_to conversation, :project
  end

  test "should have many messages" do
    conversation = create_conversation(project: @project)
    assert_respond_to conversation, :messages
  end

  test "should destroy associated messages" do
    conversation = create_conversation(project: @project)
    message = create_message(conversation)

    conversation.destroy

    assert_not Message.exists?(message.id)
  end

  # Methods
  test "generate_title_from_first_message! should set title from first user message when title is blank" do
    conversation = @project.conversations.create!(title: "New Chat")
    conversation.messages.create!(role: "user", content: "This is a very long message that should definitely be truncated because it exceeds fifty characters")

    # Set title to empty string (which passes validation but is blank)
    conversation.title = ""
    conversation.save!(validate: false)
    conversation.generate_title_from_first_message!

    # truncate(50) in Rails includes "..." so 47 chars + "..."
    assert conversation.title.length <= 50
    assert_includes conversation.title, "This is a very long message"
  end

  test "generate_title_from_first_message! should not override existing title" do
    conversation = @project.conversations.create!(title: "Custom Title")
    conversation.messages.create!(role: "user", content: "Some message")

    conversation.generate_title_from_first_message!

    assert_equal "Custom Title", conversation.title
  end

  # Scopes
  test ".recent should return conversations ordered by updated_at desc" do
    old = @project.conversations.create!(title: "Old", updated_at: 2.days.ago)
    new = @project.conversations.create!(title: "New", updated_at: Time.current)

    recent = Conversation.recent

    # New should come first
    assert recent.index(new) < recent.index(old)
  end

  test ".for_project should filter by project" do
    other_project = create_project(name: "Other")
    conv1 = create_conversation(project: @project, title: "Conv1")
    conv2 = create_conversation(project: other_project, title: "Conv2")

    result = Conversation.for_project(@project)

    assert_includes result, conv1
    assert_not_includes result, conv2
  end

  test ".recent_for_project should limit results" do
    5.times { |i| create_conversation(project: @project, title: "Chat #{i}") }

    recent = Conversation.recent_for_project(@project, 3)

    assert_equal 3, recent.length
  end
end
