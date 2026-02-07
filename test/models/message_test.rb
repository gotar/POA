# frozen_string_literal: true

require "test_helper"

class MessageTest < ActiveSupport::TestCase
  # Validations
  test "should be valid with all required attributes" do
    conversation = create_conversation
    message = Message.new(
      conversation: conversation,
      role: "user",
      content: "Hello!"
    )
    assert message.valid?
  end

  test "should require conversation" do
    message = Message.new(role: "user", content: "Hello!")
    assert_not message.valid?
    assert_includes message.errors[:conversation], "must exist"
  end

  test "should require role" do
    conversation = create_conversation
    message = Message.new(conversation: conversation, content: "Hello!", role: nil)
    assert_not message.valid?
    assert_includes message.errors[:role], "can't be blank"
  end

  test "should require valid role" do
    conversation = create_conversation
    message = Message.new(conversation: conversation, content: "Hello!", role: "invalid")
    assert_not message.valid?
    assert_includes message.errors[:role], "is not included in the list"
  end

  test "should accept valid roles" do
    conversation = create_conversation

    %w[user assistant system].each do |role|
      message = Message.new(conversation: conversation, role: role, content: "Test")
      assert message.valid?, "Expected role '#{role}' to be valid"
    end
  end

  test "should require content" do
    conversation = create_conversation
    message = Message.new(conversation: conversation, role: "user", content: nil)
    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  # Associations
  test "should belong to conversation" do
    message = Message.new
    assert_respond_to message, :conversation
  end

  # Methods
  test "to_rpc_format should return hash with role and content" do
    message = create_message(create_conversation)

    result = message.to_rpc_format

    assert_instance_of Hash, result
    assert_equal "user", result[:role]
    assert_equal "Hello, world!", result[:content]
  end

  # Ordering
  test "messages should be ordered by created_at" do
    conversation = create_conversation
    first = conversation.messages.create!(role: "user", content: "First", created_at: 1.hour.ago)
    second = conversation.messages.create!(role: "user", content: "Second", created_at: Time.current)

    messages = conversation.messages.order(:created_at)

    assert_equal [first, second], messages.to_a
  end
end
