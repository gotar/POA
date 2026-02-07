# frozen_string_literal: true

class PersonalKnowledgeController < ApplicationController
  before_action :set_project

  # GET /projects/:project_id/personal_knowledge
  def index
    load_index_data

    @suggestions = []
    @prefill = {}
  end

  # GET /projects/:project_id/personal_knowledge/search?q=...
  def search
    q = params[:q].to_s.strip
    mode = params[:mode].to_s.presence || "query"

    @q = q
    @mode = mode

    @results = if q.blank?
      []
    else
      begin
        QmdCliService.search(q, mode: mode.to_sym, limit: 20)
      rescue StandardError => e
        @error = e.message
        []
      end
    end

    respond_to do |format|
      format.turbo_stream
      format.html { render :index }
    end
  end

  # GET /projects/:project_id/personal_knowledge/note?path=topics/foo.md
  def show
    @path = params[:path].to_s
    @content = PersonalKnowledgeService.read(@path)
    @meta = PersonalKnowledgeService.describe_file(File.join(PersonalKnowledgeService.base_dir, @path))
  end

  # GET /projects/:project_id/personal_knowledge/note/edit?path=...
  def edit
    @path = params[:path].to_s
    @content = PersonalKnowledgeService.read(@path)
  end

  # PATCH /projects/:project_id/personal_knowledge/note
  def update
    @path = params[:path].to_s
    content = params[:content].to_s

    PersonalKnowledgeService.write(@path, content)

    redirect_to project_personal_knowledge_note_path(@project, path: @path), notice: "Note updated"
  rescue PersonalKnowledgeService::Error => e
    redirect_to project_personal_knowledge_path(@project), alert: e.message
  end

  # POST /projects/:project_id/personal_knowledge/topics
  def create_topic
    title = params[:title].to_s
    body = params[:body].to_s
    tags = params[:tags].to_s.split(/[,\s]+/).reject(&:blank?)
    source = params[:source].to_s.presence
    version = params[:version].to_s.presence

    existing_path = params[:existing_path].to_s.presence
    force = params[:force].to_s == "1"

    if title.blank?
      redirect_to project_personal_knowledge_path(@project), alert: "Title is required"
      return
    end

    # If user chose an existing note, update it instead of creating a new one.
    if existing_path.present?
      rel = PersonalKnowledgeService.merge_into!(existing_path, update_text: body, tags: tags, source: source, version: version)
      PersonalKnowledgeReindexJob.perform_later
      redirect_to project_personal_knowledge_note_path(@project, path: rel), notice: "Updated existing topic"
      return
    end

    # De-dupe: suggest possible existing topics before creating a new one.
    unless force
      @suggestions = suggest_duplicates(title)

      if @suggestions.any?
        load_index_data
        @prefill = {
          title: title,
          body: body,
          tags: params[:tags].to_s,
          source: source,
          version: version
        }

        respond_to do |format|
          format.turbo_stream { render :create_topic, status: :unprocessable_entity }
          format.html { render :index, status: :unprocessable_entity }
        end
        return
      end
    end

    rel = PersonalKnowledgeService.create_topic!(title: title, body: body, tags: tags, source: source, version: version)

    PersonalKnowledgeReindexJob.perform_later

    redirect_to project_personal_knowledge_note_path(@project, path: rel), notice: "Topic created"
  end

  # POST /projects/:project_id/personal_knowledge/reindex
  def reindex
    PersonalKnowledgeReindexJob.perform_later

    respond_to do |format|
      format.html { redirect_to project_personal_knowledge_path(@project), notice: "Reindex queued" }
      format.turbo_stream
    end
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def load_index_data
    @stats = PersonalKnowledgeService.stats
    @topics = PersonalKnowledgeService.list(kind: :topics, limit: 30)
    @daily = PersonalKnowledgeService.list(kind: :daily, limit: 14)

    @qmd_status = begin
      QmdCliService.status
    rescue StandardError => e
      "QMD status unavailable: #{e.message}"
    end
  end

  def suggest_duplicates(title)
    # Use QMD hybrid query; show suggestions only for existing TOPIC notes.
    results = QmdCliService.search(title, mode: :query, limit: 6)

    results.select do |r|
      rel = r["file"].to_s.sub(%r{\Aqmd://[^/]+/}i, "")
      rel.start_with?("topics/")
    end
  rescue StandardError
    []
  end
end
