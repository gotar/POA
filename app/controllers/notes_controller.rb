# frozen_string_literal: true

class NotesController < ApplicationController
  before_action :set_project
  before_action :set_note, only: %i[show update destroy]

  # GET /projects/:project_id/notes
  def index
    @notes = @project.notes.recent
    @note = @project.notes.build(category: "context")

    respond_to do |format|
      format.html
      format.json { render json: @notes }
    end
  end

  # GET /projects/:project_id/notes/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @note }
    end
  end

  # POST /projects/:project_id/notes
  def create
    @note = @project.notes.build(note_params)

    if @note.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @project, notice: "Note added" }
        format.json { render json: @note, status: :created }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_error }
        format.html { redirect_to @project, alert: "Failed to add note" }
        format.json { render json: { errors: @note.errors }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/:project_id/notes/:id
  def update
    if @note.update(note_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @project, notice: "Note updated" }
        format.json { render json: @note }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_error }
        format.html { redirect_to @project, alert: "Failed to update note" }
        format.json { render json: { errors: @note.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/:project_id/notes/:id
  def destroy
    @note.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @project, notice: "Note deleted" }
      format.json { head :no_content }
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_note
    @note = @project.notes.find(params[:id])
  end

  def note_params
    params.expect(note: %i[title content category])
  end

  def render_error
    render turbo_stream: turbo_stream.replace(
      "note_form",
      partial: "notes/form",
      locals: { project: @project, note: @note }
    )
  end
end
