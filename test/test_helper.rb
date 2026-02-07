# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  include Rails.application.routes.url_helpers
end

# Helper for creating test data
module TestHelpers
  def create_project(overrides = {})
    Project.create!({
      name: "Test Project",
      color: "#8B5CF6",
      icon: "📁"
    }.merge(overrides))
  end

  def create_conversation(overrides = {})
    project = overrides[:project] || create_project
    Conversation.create!({
      title: "Test Conversation",
      project: project
    }.merge(overrides))
  end

  def create_message(conversation, overrides = {})
    conversation.messages.create!({
      role: "user",
      content: "Hello, world!"
    }.merge(overrides))
  end

  def create_todo(project, overrides = {})
    project.todos.create!({
      content: "Test todo",
      status: "pending"
    }.merge(overrides))
  end

  def create_knowledge_base(project, overrides = {})
    project.knowledge_bases.create!({
      title: "Test Knowledge Base",
      content: "Knowledge base content",
      category: "context",
      tags: ["test"]
    }.merge(overrides))
  end
end

ActiveSupport::TestCase.include(TestHelpers)
