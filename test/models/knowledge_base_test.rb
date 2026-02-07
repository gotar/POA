# frozen_string_literal: true

require "test_helper"

class KnowledgeBaseTest < ActiveSupport::TestCase
  setup do
    @project = create_project
  end

  # Validations
  test "should be valid with required attributes" do
    kb = @project.knowledge_bases.build(title: "Test KB", content: "Content", category: "context")
    assert kb.valid?
  end

  test "should require title" do
    kb = @project.knowledge_bases.build(content: "Content", category: "context")
    assert_not kb.valid?
    assert_includes kb.errors[:title], "can't be blank"
  end

  test "should require content" do
    kb = @project.knowledge_bases.build(title: "Test", category: "context")
    assert_not kb.valid?
    assert_includes kb.errors[:content], "can't be blank"
  end

  test "should require valid category" do
    kb = @project.knowledge_bases.build(title: "Test", content: "Content", category: "invalid")
    assert_not kb.valid?
    assert_includes kb.errors[:category], "is not included in the list"
  end

  test "should allow valid categories" do
    %w[context reference code example].each do |category|
      kb = @project.knowledge_bases.build(title: "Test", content: "Content", category: category)
      assert kb.valid?, "Category #{category} should be valid"
    end
  end

  # Tags serialization
  test "should serialize tags as array" do
    kb = @project.knowledge_bases.create!(title: "Test", content: "Content", category: "context", tags: ["ai", "ml"])
    kb.reload
    assert_equal ["ai", "ml"], kb.tags
  end

  test "should normalize tags to lowercase" do
    kb = @project.knowledge_bases.build(title: "Test", content: "Content", category: "context", tags: ["AI", "ML", "Python"])
    kb.save!
    assert_equal ["ai", "ml", "python"], kb.tags
  end

  # Search functionality
  test "should search by title" do
    kb1 = @project.knowledge_bases.create!(title: "Python Guide", content: "Content", category: "reference")
    kb2 = @project.knowledge_bases.create!(title: "Ruby Guide", content: "Content", category: "reference")

    results = KnowledgeBase.search("Python", @project)
    assert_includes results, kb1
    assert_not_includes results, kb2
  end

  test "should search by content" do
    kb1 = @project.knowledge_bases.create!(title: "Guide", content: "Python programming", category: "reference")
    kb2 = @project.knowledge_bases.create!(title: "Guide", content: "Ruby programming", category: "reference")

    results = KnowledgeBase.search("Python", @project)
    assert_includes results, kb1
    assert_not_includes results, kb2
  end

  test "should filter search by project" do
    other_project = create_project(name: "Other")
    kb1 = @project.knowledge_bases.create!(title: "Python Guide", content: "Content", category: "reference")
    kb2 = other_project.knowledge_bases.create!(title: "Python Guide", content: "Content", category: "reference")

    results = KnowledgeBase.search("Python", @project)
    assert_includes results, kb1
    assert_not_includes results, kb2
  end

  # Category filtering
  test "should filter by category" do
    kb1 = @project.knowledge_bases.create!(title: "Context KB", content: "Content", category: "context")
    kb2 = @project.knowledge_bases.create!(title: "Reference KB", content: "Content", category: "reference")

    context_results = KnowledgeBase.by_category("context", @project)
    assert_includes context_results, kb1
    assert_not_includes context_results, kb2
  end

  test "should order by category alphabetically" do
    kb1 = @project.knowledge_bases.create!(title: "Z KB", content: "Content", category: "context")
    kb2 = @project.knowledge_bases.create!(title: "A KB", content: "Content", category: "context")

    results = KnowledgeBase.by_category("context", @project)
    assert_equal kb2, results.first
    assert_equal kb1, results.second
  end

  # Recent ordering
  test "should order recent by created_at desc" do
    kb1 = @project.knowledge_bases.create!(title: "Old KB", content: "Content", category: "context")
    kb1.update_columns(created_at: 1.day.ago)
    kb2 = @project.knowledge_bases.create!(title: "New KB", content: "Content", category: "context")

    results = KnowledgeBase.recent(@project)
    assert_equal kb2, results.first
    assert_equal kb1, results.second
  end

  test "should limit recent results" do
    5.times do |i|
      @project.knowledge_bases.create!(title: "KB #{i}", content: "Content", category: "context")
    end

    results = KnowledgeBase.recent(@project, 3)
    assert_equal 3, results.count
  end

  # Content analysis
  test "should extract keywords from content" do
    kb = @project.knowledge_bases.create!(title: "Test", content: "This is a test with keywords", category: "context")
    keywords = kb.keywords
    assert_includes keywords, "test"
    assert_includes keywords, "keywords"
    assert_not_includes keywords, "is" # too short
    assert_not_includes keywords, "a"  # too short
  end

  test "should detect code blocks" do
    kb1 = @project.knowledge_bases.create!(title: "With Code", content: "```python\nprint('hello')\n```", category: "code")
    kb2 = @project.knowledge_bases.create!(title: "No Code", content: "Just text content", category: "reference")

    assert kb1.has_code?
    assert_not kb2.has_code?
  end

  test "should extract code blocks" do
    kb = @project.knowledge_bases.create!(title: "Code KB", content: "```python\nprint('hello')\n```\n```ruby\nputs 'world'\n```", category: "code")
    blocks = kb.code_blocks

    assert_equal 2, blocks.length
    assert_equal "python", blocks[0][0]
    assert_equal "ruby", blocks[1][0]
  end
end
