# frozen_string_literal: true

class ProjectsController < ApplicationController
  def index
    @projects = Project.active.recent
    @archived_projects = Project.archived.recent
    @empty_projects = Project.active.empty
    @old_projects = Project.active.old.where.not(id: @empty_projects.pluck(:id))
    @project = Project.new
  end

  def show
    @project = Project.find(params[:id])
    @conversations = @project.conversations.includes(:messages).recent.limit(10)
    @todos = @project.todos.active.by_position
    @notes = @project.notes.context.recent.limit(5)

    # For new conversation form
    @new_conversation = @project.conversations.build
  end

  def create
    @project = Project.new(project_params)

    if @project.save
      @project.ensure_color!
      redirect_to @project, notice: "Project created"
    else
      handle_validation_error(:index)
    end
  end

  def update
    @project = Project.find(params[:id])

    if @project.update(project_params)
      redirect_to @project, notice: "Project updated"
    else
      handle_validation_error(:show)
    end
  end

  def destroy
    @project = Project.find(params[:id])
    @project.destroy!
    redirect_to projects_path, notice: "Project deleted"
  end

  def archive
    @project = Project.find(params[:id])
    @project.archive!
    redirect_to projects_path, notice: "Project archived"
  end

  def unarchive
    @project = Project.find(params[:id])
    @project.unarchive!
    redirect_to projects_path, notice: "Project restored"
  end

  def bulk_delete
    project_ids = params[:project_ids] || []
    count = Project.where(id: project_ids).destroy_all.size
    redirect_to projects_path, notice: "Deleted #{count} projects"
  end

  def bulk_archive
    project_ids = params[:project_ids] || []
    count = Project.where(id: project_ids).update_all(archived: true)
    redirect_to projects_path, notice: "Archived #{count} projects"
  end

  def bulk_unarchive
    project_ids = params[:project_ids] || []
    count = Project.where(id: project_ids).update_all(archived: false)
    redirect_to projects_path, notice: "Restored #{count} projects"
  end

  def context
    @project = Project.find(params[:id])

    # Return project context for AI (todos, notes)
    render json: {
      project: {
        name: @project.name,
        description: @project.description
      },
      active_todos: @project.active_todos.map(&:to_h),
      context_notes: @project.context_notes.map { |n| { title: n.title, content: n.content } }
    }
  end

  private

  def project_params
    params.expect(project: %i[name description color icon])
  end

  def handle_validation_error(template)
    @projects = Project.recent
    render template, status: :unprocessable_entity
  end
end
