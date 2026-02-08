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

    if q.blank?
      @results = []
      respond_to do |format|
        format.turbo_stream
        format.html { render :index }
      end
      return
    end

    # Fast mode inline; heavy modes async via Solid Queue.
    if %w[vsearch query].include?(mode)
      ks = KnowledgeSearch.create!(query: q, mode: mode, status: "queued")
      KnowledgeSearchJob.perform_later(ks.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "kb_search",
            partial: "knowledge/async_search_frame",
            locals: { knowledge_search: ks }
          )
        end
        format.html { redirect_to knowledge_path }
      end
      return
    end

    @results = begin
      QmdCliService.search(q, mode: mode.to_sym, limit: 20)
    rescue StandardError => e
      @error = e.message
      []
    end

    respond_to do |format|
      format.turbo_stream
      format.html { render :index }
    end
  end

  def search_status
    @knowledge_search = KnowledgeSearch.find(params[:id])
    render layout: false
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

  # GET /knowledge/export
  def export
    PersonalKnowledgeService.ensure_setup!

    base = PersonalKnowledgeService.base_dir
    ts = Time.current.strftime("%Y%m%d-%H%M%S")

    require "stringio"
    require "zlib"
    require "rubygems/package"

    io = StringIO.new(+"")
    io.binmode

    Zlib::GzipWriter.wrap(io) do |gz|
      Gem::Package::TarWriter.new(gz) do |tar|
        Dir.chdir(base) do
          Dir.glob("**/*", File::FNM_DOTMATCH).each do |path|
            next if path == "." || path == ".."
            next if path.start_with?(".git/")
            next if File.directory?(path)

            data = File.binread(path)
            mode = File.stat(path).mode
            tar.add_file_simple(path, mode, data.bytesize) { |tio| tio.write(data) }
          end
        end
      end
    end

    send_data io.string,
              filename: "pi-knowledge-#{ts}.tar.gz",
              type: "application/gzip",
              disposition: "attachment"
  end

  # GET /knowledge/governance
  def governance
    PersonalKnowledgeService.ensure_setup!

    @stats = PersonalKnowledgeService.stats

    @stale_days = params[:stale_days].to_i
    @stale_days = 90 if @stale_days <= 0
    stale_before = @stale_days.days.ago

    base = PersonalKnowledgeService.base_dir
    abs_topics = Dir.glob(File.join(base, "topics", "**", "*.md"))

    @topics = abs_topics.map { |abs| PersonalKnowledgeService.describe_file(abs) }
      .sort_by { |h| -(h[:updated_at]&.to_i || 0) }

    @archived_topics = @topics.select { |t| t[:status].to_s == "archived" }
    @active_topics = @topics.reject { |t| t[:status].to_s == "archived" }

    @stale_topics = @active_topics.select { |t| t[:updated_at].present? && t[:updated_at] < stale_before }
    @untagged_topics = @active_topics.select { |t| Array(t[:tags]).empty? }

    @large_topics = abs_topics.filter_map do |abs|
      sz = File.size(abs) rescue nil
      next unless sz
      next unless sz > 20_000

      meta = PersonalKnowledgeService.describe_file(abs)
      meta.merge(bytes: sz)
    end.sort_by { |h| -h[:bytes].to_i }

    load_pi_sessions
  end

  # POST /knowledge/note/archive
  def archive_note
    rel = params[:path].to_s
    PersonalKnowledgeService.update_frontmatter!(rel, { "status" => "archived" })
    PersonalKnowledgeReindexJob.perform_later

    redirect_back fallback_location: knowledge_governance_path, notice: "Note archived"
  rescue PersonalKnowledgeService::Error => e
    redirect_back fallback_location: knowledge_governance_path, alert: e.message
  end

  # POST /knowledge/note/unarchive
  def unarchive_note
    rel = params[:path].to_s
    PersonalKnowledgeService.update_frontmatter!(rel, { "status" => nil })
    PersonalKnowledgeReindexJob.perform_later

    redirect_back fallback_location: knowledge_governance_path, notice: "Note restored"
  rescue PersonalKnowledgeService::Error => e
    redirect_back fallback_location: knowledge_governance_path, alert: e.message
  end

  # DELETE /knowledge/pi_sessions?path=snippets/pi-sessions/...
  def delete_pi_session
    rel = params[:path].to_s

    unless rel.start_with?("snippets/pi-sessions/")
      redirect_back fallback_location: knowledge_governance_path, alert: "Invalid pi session path"
      return
    end

    abs = PersonalKnowledgeService.resolve_rel!(rel)
    File.delete(abs)

    PersonalKnowledgeReindexJob.perform_later
    redirect_back fallback_location: knowledge_governance_path, notice: "Session transcript deleted"
  rescue PersonalKnowledgeService::Error, StandardError => e
    redirect_back fallback_location: knowledge_governance_path, alert: e.message
  end

  private

  def load_pi_sessions(limit: 80)
    base = PersonalKnowledgeService.base_dir
    abs_sessions = Dir.glob(File.join(base, "snippets", "pi-sessions", "**", "*.md"))

    @pi_sessions_count = abs_sessions.count
    @pi_sessions = abs_sessions
      .sort_by { |path| -File.mtime(path).to_i }
      .first(limit)
      .map { |path| PersonalKnowledgeService.describe_file(path) }
  rescue StandardError
    @pi_sessions_count = 0
    @pi_sessions = []
  end

  def suggest_duplicates(title)
    results = QmdCliService.search(title, mode: :search, limit: 6)

    results.select do |r|
      rel = r["file"].to_s.sub(%r{\Aqmd://[^/]+/}i, "")
      rel.start_with?("topics/")
    end
  rescue StandardError
    []
  end
end
