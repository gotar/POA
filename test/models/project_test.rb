# frozen_string_literal: true

require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  # Validations
  test "should be valid with name" do
    project = Project.new(name: "Test Project")
    assert project.valid?
  end

  test "should be invalid without name" do
    project = Project.new(name: nil)
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "name should not exceed 100 characters" do
    project = Project.new(name: "x" * 101)
    assert_not project.valid?
  end

  test "color should be valid hex format" do
    project = Project.new(name: "Test", color: "#8B5CF6")
    assert project.valid?
  end

  test "color should reject invalid format" do
    project = Project.new(name: "Test", color: "red")
    assert_not project.valid?
  end

  # Associations
  test "should have many conversations" do
    project = Project.create!(name: "Test")
    assert_respond_to project, :conversations
  end

  test "should destroy associated conversations" do
    project = Project.create!(name: "Test")
    conversation = project.conversations.create!(title: "Chat")

    project.destroy

    assert_not Conversation.exists?(conversation.id)
  end

  test "should have many todos" do
    project = Project.create!(name: "Test")
    assert_respond_to project, :todos
  end

  test "should have many notes" do
    project = Project.create!(name: "Test")
    assert_respond_to project, :notes
  end

  # Methods
  test "active_todos should return non-completed todos" do
    project = Project.create!(name: "Test")
    pending = project.todos.create!(content: "Pending", status: "pending")
    completed = project.todos.create!(content: "Done", status: "completed")

    active = project.active_todos

    assert_includes active, pending
    assert_not_includes active, completed
  end

  test "context_notes should return notes with context category" do
    project = Project.create!(name: "Test")
    context = project.notes.create!(title: "Context", content: "Info", category: "context")
    other = project.notes.create!(title: "Reference", content: "Ref", category: "reference")

    notes = project.context_notes

    assert_includes notes, context
    assert_not_includes notes, other
  end

  test "summary should return stats" do
    project = Project.create!(name: "Test")
    project.conversations.create!(title: "Chat")
    project.todos.create!(content: "Task", status: "pending")
    project.todos.create!(content: "Done", status: "completed")

    summary = project.summary

    assert_equal 1, summary[:conversations_count]
    assert_equal 1, summary[:todos_pending]
    assert_equal 1, summary[:todos_completed]
  end

  test "ensure_color! should set a random color if missing" do
    project = Project.create!(name: "Test", color: nil)

    project.ensure_color!

    assert project.color.present?
    assert_match(/#[0-9A-Fa-f]{6}/, project.color)
  end
end
