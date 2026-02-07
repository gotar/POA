# frozen_string_literal: true

class KnowledgeBasesController < ApplicationController
  before_action :set_project
  before_action :set_knowledge_base, only: %i[show edit update destroy]

  # GET /projects/:project_id/knowledge_bases
  def index
    @knowledge_bases = @project.knowledge_bases.recent
    @knowledge_base = @project.knowledge_bases.build

    # Filter by category if specified
    if params[:category].present?
      @knowledge_bases = @knowledge_bases.where(category: params[:category])
    end

    # Search if query provided
    if params[:q].present?
      if params[:semantic] == 'true'
        @knowledge_bases = KnowledgeBase.semantic_search(params[:q], @project, limit: 50)
      else
        @knowledge_bases = @knowledge_bases.where(
          "LOWER(title) LIKE LOWER(?) OR LOWER(content) LIKE LOWER(?)",
          "%#{params[:q]}%", "%#{params[:q]}%"
        )
      end
    end
  end

  # GET /projects/:project_id/knowledge_bases/:id
  def show
  end

  # GET /projects/:project_id/knowledge_bases/new
  def new
    @knowledge_base = @project.knowledge_bases.build
  end

  # GET /projects/:project_id/knowledge_bases/:id/edit
  def edit
  end

  # POST /projects/:project_id/knowledge_bases
  def create
    @knowledge_base = @project.knowledge_bases.build(knowledge_base_params)

    if @knowledge_base.save
      respond_to do |format|
        format.html { redirect_to [@project, @knowledge_base], notice: "Knowledge base item created" }
        format.turbo_stream { redirect_to [@project, @knowledge_base] }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/:project_id/knowledge_bases/:id
  def update
    if @knowledge_base.update(knowledge_base_params)
      respond_to do |format|
        format.html { redirect_to [@project, @knowledge_base], notice: "Knowledge base item updated" }
        format.turbo_stream { redirect_to [@project, @knowledge_base] }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/:project_id/knowledge_bases/:id
  def destroy
    @knowledge_base.destroy!

    respond_to do |format|
      format.html { redirect_to project_knowledge_bases_path(@project), notice: "Knowledge base item deleted" }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_knowledge_base
    @knowledge_base = @project.knowledge_bases.find(params[:id])
  end

  def knowledge_base_params
    params.expect(knowledge_base: %i[title content category]).tap do |whitelist|
      if params[:knowledge_base][:tags].present?
        # Parse comma-separated tags into array
        tags_string = params[:knowledge_base][:tags]
        whitelist[:tags] = tags_string.split(',').map(&:strip).reject(&:blank?)
      end
    end
  end
end