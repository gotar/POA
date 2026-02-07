# frozen_string_literal: true

class KnowledgeController < ApplicationController
  # GET /knowledge
  def index
    @stats = PersonalKnowledgeService.stats
    @topics = PersonalKnowledgeService.list(kind: :topics, limit: 30)
    @daily = PersonalKnowledgeService.list(kind: :daily, limit: 14)

    @suggestions = []
    @prefill = {}

    @qmd_status = begin
      QmdCliService.status
    rescue StandardError => e
      "QMD status unavailable: #{e.message}"
    end
  end

  # GET /knowledge/search?q=...
  def search
    q = params[:q].to_s.strip
    mode = params[:mode].to_s.presence || "search"

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

  # GET /knowledge/note?path=topics/foo.md
  def show
    @path = params[:path].to_s
    @content = PersonalKnowledgeService.read(@path)
    @meta = PersonalKnowledgeService.describe_file(File.join(PersonalKnowledgeService.base_dir, @path))
  end

  # GET /knowledge/note/edit?path=...
  def edit
    @path = params[:path].to_s
    @content = PersonalKnowledgeService.read(@path)
  end

  # PATCH /knowledge/note
  def update
    @path = params[:path].to_s
    content = params[:content].to_s

    PersonalKnowledgeService.write(@path, content)
    PersonalKnowledgeReindexJob.perform_later

    redirect_to knowledge_note_path(path: @path), notice: "Note updated"
  rescue PersonalKnowledgeService::Error => e
    redirect_to knowledge_path, alert: e.message
  end

  # POST /knowledge/topics
  def create_topic
    title = params[:title].to_s
    body = params[:body].to_s
    tags = params[:tags].to_s.split(/[\s,]+/).reject(&:blank?)
    source = params[:source].to_s.presence
    version = params[:version].to_s.presence

    existing_path = params[:existing_path].to_s.presence
    force = params[:force].to_s == "1"

    if title.blank?
      redirect_to knowledge_path, alert: "Title is required"
      return
    end

    if existing_path.present?
      rel = PersonalKnowledgeService.merge_into!(existing_path, update_text: body, tags: tags, source: source, version: version)
      PersonalKnowledgeReindexJob.perform_later
      redirect_to knowledge_note_path(path: rel), notice: "Updated existing topic"
      return
    end

    unless force
      @suggestions = suggest_duplicates(title)
      if @suggestions.any?
        @stats = PersonalKnowledgeService.stats
        @topics = PersonalKnowledgeService.list(kind: :topics, limit: 30)
        @daily = PersonalKnowledgeService.list(kind: :daily, limit: 14)
        @qmd_status = QmdCliService.status rescue ""

        @prefill = {
          title: title,
          body: body,
          tags: params[:tags].to_s,
          source: source,
          version: version
        }

        respond_to do |format|
          format.turbo_stream { render "knowledge/create_topic", status: :unprocessable_entity }
          format.html { render :index, status: :unprocessable_entity }
        end
        return
      end
    end

    rel = PersonalKnowledgeService.create_topic!(title: title, body: body, tags: tags, source: source, version: version)
    PersonalKnowledgeReindexJob.perform_later

    redirect_to knowledge_note_path(path: rel), notice: "Topic created"
  end

  # POST /knowledge/remember
  def remember
    destination = params[:destination].to_s
    title = params[:title].to_s
    content = params[:content].to_s
    tags = params[:tags].to_s.split(/[,\s]+/).reject(&:blank?)
    source = params[:source].to_s.presence
    version = params[:version].to_s.presence

    if content.blank?
      respond_to do |format|
        format.html { redirect_back fallback_location: knowledge_path, alert: "Nothing to remember" }
        format.turbo_stream { render turbo_stream: turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: "Nothing to remember", type: :error }) }
      end
      return
    end

    case destination
    when "user"
      PersonalKnowledgeService.append_to_user!(content, label: title.presence)
    when "memory"
      PersonalKnowledgeService.append_to_memory!(content, label: title.presence)
    when "topic"
      topic_title = title.presence || content.lines.first.to_s.strip.truncate(80)
      PersonalKnowledgeService.create_topic!(title: topic_title, body: content, tags: tags, source: source, version: version)
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: knowledge_path, alert: "Invalid destination" }
        format.turbo_stream { render turbo_stream: turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: "Invalid destination", type: :error }) }
      end
      return
    end

    PersonalKnowledgeReindexJob.perform_later

    respond_to do |format|
      format.html { redirect_back fallback_location: knowledge_path, notice: "Saved to knowledge" }
      format.turbo_stream
    end
  rescue PersonalKnowledgeService::Error => e
    respond_to do |format|
      format.html { redirect_back fallback_location: knowledge_path, alert: e.message }
      format.turbo_stream { render turbo_stream: turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: e.message, type: :error }) }
    end
  end

  # POST /knowledge/reindex
  def reindex
    PersonalKnowledgeReindexJob.perform_later

    respond_to do |format|
      format.html { redirect_to knowledge_path, notice: "Reindex queued" }
      format.turbo_stream
    end
  end

  private

  def suggest_duplicates(title)
    results = QmdCliService.search(title, mode: :query, limit: 6)

    results.select do |r|
      rel = r["file"].to_s.sub(%r{\Aqmd://[^/]+/}i, "")
      rel.start_with?("topics/")
    end
  rescue StandardError
    []
  end
end
