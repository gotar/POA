# frozen_string_literal: true

class TodosController < ApplicationController
  before_action :set_project
  before_action :set_todo, only: %i[update destroy start complete cancel reopen]

  # GET /projects/:project_id/todos
  def index
    @todos = @project.todos.by_position
    @todo = @project.todos.build

    respond_to do |format|
      format.html
      format.json { render json: @todos.map(&:to_h) }
    end
  end

  # POST /projects/:project_id/todos
  def create
    @todo = @project.todos.build(todo_params)
    @todo.status ||= "pending"
    @todo.position ||= @project.todos.maximum(:position).to_i + 1

    if @todo.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @project, notice: "Todo added" }
        format.json { render json: @todo.to_h, status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_error }
        format.html { redirect_to @project, alert: "Failed to add todo" }
        format.json { render json: { errors: @todo.errors }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/:project_id/todos/:id
  def update
    if @todo.update(todo_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @project, notice: "Todo updated" }
        format.json { render json: @todo.to_h }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_error }
        format.html { redirect_to @project, alert: "Failed to update todo" }
        format.json { render json: { errors: @todo.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/:project_id/todos/:id
  def destroy
    @todo.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project, notice: "Todo deleted" }
      format.json { head :no_content }
    end
  end

  # POST /projects/:project_id/todos/:id/start
  def start
    @todo.start!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
      format.json { render json: @todo.to_h }
    end
  end

  # POST /projects/:project_id/todos/:id/complete
  def complete
    @todo.complete!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
      format.json { render json: @todo.to_h }
    end
  end

  # POST /projects/:project_id/todos/:id/cancel
  def cancel
    @todo.cancel!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
      format.json { render json: @todo.to_h }
    end
  end

  # POST /projects/:project_id/todos/:id/reopen
  def reopen
    @todo.reopen!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project }
      format.json { render json: @todo.to_h }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_todo
    @todo = @project.todos.find(params[:id])
  end

  def todo_params
    params.expect(todo: %i[content status priority position])
  end

  def render_error
    render turbo_stream: turbo_stream.replace(
      "todo_form",
      partial: "todos/form",
      locals: { project: @project, todo: @todo }
    )
  end
end
