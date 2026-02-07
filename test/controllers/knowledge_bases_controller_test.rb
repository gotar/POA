# frozen_string_literal: true

require "test_helper"

class KnowledgeBasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @project = create_project
  end

  # Index
  test "should get index" do
    get project_knowledge_bases_url(@project)
    assert_response :success
  end

  test "index should show knowledge bases for project" do
    kb = @project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    get project_knowledge_bases_url(@project)

    assert_response :success
    assert_includes assigns(:knowledge_bases), kb
  end

  test "index should filter by category" do
    context_kb = @project.knowledge_bases.create!(title: "Context KB", content: "Content", category: "context")
    code_kb = @project.knowledge_bases.create!(title: "Code KB", content: "Content", category: "code")

    get project_knowledge_bases_url(@project, category: "context")

    assert_response :success
    results = assigns(:knowledge_bases)
    assert_includes results, context_kb
    assert_not_includes results, code_kb
  end

  test "index should search by query" do
    kb1 = @project.knowledge_bases.create!(title: "Python Guide", content: "Content", category: "reference")
    kb2 = @project.knowledge_bases.create!(title: "Ruby Guide", content: "Content", category: "reference")

    get project_knowledge_bases_url(@project, q: "Python")

    assert_response :success
    results = assigns(:knowledge_bases)
    assert_includes results, kb1
    assert_not_includes results, kb2
  end

  # Show
  test "should show knowledge base" do
    kb = @project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    get project_knowledge_basis_url(@project, kb)

    assert_response :success
    assert_equal kb, assigns(:knowledge_base)
  end

  test "should not show knowledge base from different project" do
    other_project = create_project(name: "Other")
    kb = other_project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    get project_knowledge_basis_url(@project, kb)

    assert_response :not_found
  end

  # New
  test "should get new" do
    get new_project_knowledge_basis_url(@project)

    assert_response :success
    assert_instance_of KnowledgeBase, assigns(:knowledge_base)
    assert_equal @project, assigns(:knowledge_base).project
  end

  # Create
  test "should create knowledge base" do
    assert_difference("KnowledgeBase.count") do
      post project_knowledge_bases_url(@project), params: {
        knowledge_base: { title: "New KB", content: "Content", category: "context", tags: "ai, ml" }
      }
    end

    kb = KnowledgeBase.last
    assert_equal "New KB", kb.title
    assert_equal "Content", kb.content
    assert_equal "context", kb.category
    assert_equal ["ai", "ml"], kb.tags
    assert_redirected_to [@project, kb]
  end

  test "should not create invalid knowledge base" do
    assert_no_difference("KnowledgeBase.count") do
      post project_knowledge_bases_url(@project), params: {
        knowledge_base: { title: "", content: "Content", category: "context" }
      }
    end

    assert_response :unprocessable_entity
  end

  # Edit
  test "should get edit" do
    kb = @project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    get edit_project_knowledge_basis_url(@project, kb)

    assert_response :success
    assert_equal kb, assigns(:knowledge_base)
  end

  # Update
  test "should update knowledge base" do
    kb = @project.knowledge_bases.create!(title: "Old Title", content: "Old Content", category: "context")

    patch project_knowledge_basis_url(@project, kb), params: {
      knowledge_base: { title: "New Title", content: "New Content", category: "reference" }
    }

    kb.reload
    assert_equal "New Title", kb.title
    assert_equal "New Content", kb.content
    assert_equal "reference", kb.category
    assert_redirected_to [@project, kb]
  end

  test "should not update with invalid data" do
    kb = @project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    patch project_knowledge_basis_url(@project, kb), params: {
      knowledge_base: { title: "", content: "Content", category: "context" }
    }

    kb.reload
    assert_equal "Test KB", kb.title
    assert_response :unprocessable_entity
  end

  # Destroy
  test "should destroy knowledge base" do
    kb = @project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    assert_difference("KnowledgeBase.count", -1) do
      delete project_knowledge_basis_url(@project, kb)
    end

    assert_redirected_to project_knowledge_bases_url(@project)
  end

  test "should not destroy knowledge base from different project" do
    other_project = create_project(name: "Other")
    kb = other_project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    assert_no_difference("KnowledgeBase.count") do
      delete project_knowledge_basis_url(@project, kb)
    end

    assert_response :not_found
  end

  # Project isolation
  test "should not access knowledge base from different project" do
    other_project = create_project(name: "Other")
    kb = other_project.knowledge_bases.create!(title: "Test KB", content: "Content", category: "context")

    get project_knowledge_basis_url(@project, kb)
    assert_response :not_found

    patch project_knowledge_basis_url(@project, kb), params: { knowledge_base: { title: "Updated" } }
    assert_response :not_found

    delete project_knowledge_basis_url(@project, kb)
    assert_response :not_found
  end
end
