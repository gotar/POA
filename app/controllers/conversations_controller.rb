# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :set_project

  # GET /projects/:project_id/conversations
  def index
    @show_archived = params[:show_archived].to_s == "1"
    base = @project.conversations
    base = base.unarchived unless @show_archived

    @conversations = base.recent
    @archived_count = @project.conversations.archived.count
    @conversation = @project.conversations.build
  end

  # GET /projects/:project_id/conversations/:id
  def show
    @conversation = @project.conversations.find(params[:id])
    @messages = @conversation.messages.order(:created_at)
    @new_message = @conversation.messages.build(role: "user")

    # Defaults for model picker (persist on first view so subsequent jobs use it)
    if @conversation.pi_provider.blank? || @conversation.pi_model.blank?
      defaults = PiModelsService.default_provider_model
      @conversation.update_columns(pi_provider: defaults[:provider], pi_model: defaults[:model])
    end

    # Load project context for sidebar
    @todos = @project.todos.active.by_position
    @notes = @project.notes.context.recent.limit(5)
  end

  # POST /projects/:project_id/conversations
  def create
    @conversation = @project.conversations.build(conversation_params)
    @conversation.title ||= "New Chat"

    if @conversation.save
      redirect_to [@project, @conversation]
    else
      @conversations = @project.conversations.recent
      render :index, status: :unprocessable_entity
    end
  end

  # PATCH /projects/:project_id/conversations/:id
  def update
    @conversation = @project.conversations.find(params[:id])

    frame_id = params[:frame_id].to_s
    frame_id = "conversation_title" if frame_id.blank?
    frame_id = "conversation_title" unless frame_id.match?(/\Aconversation_title(_\d+)?\z/)

    if @conversation.update(conversation_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            frame_id,
            partial: "conversations/inline_title",
            locals: { project: @project, conversation: @conversation, frame_id: frame_id }
          )
        end
        format.html { redirect_to [@project, @conversation], notice: "Chat updated" }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            frame_id,
            partial: "conversations/inline_title",
            locals: { project: @project, conversation: @conversation, frame_id: frame_id }
          ), status: :unprocessable_entity
        end

        format.html do
          @messages = @conversation.messages.order(:created_at)
          @new_message = @conversation.messages.build(role: "user")
          render :show, status: :unprocessable_entity
        end
      end
    end
  end

  # GET /projects/:project_id/conversations/:id/available_models
  def available_models
    conversation = @project.conversations.find(params[:id])

    # Optional query filter (simple contains on label/provider/model)
    q = params[:q].to_s.strip.downcase
    limit = params[:limit].to_i
    limit = 50 if limit <= 0
    limit = 200 if limit > 200

    models = PiModelsService.models

    if q.present?
      models = models.select do |m|
        s = "#{m['label']} #{m['provider']} #{m['model']}".downcase
        s.include?(q)
      end
    end

    # Keep selected model near the front if present
    selected = "#{conversation.pi_provider}:#{conversation.pi_model}"
    models.sort_by! do |m|
      v = "#{m['provider']}:#{m['model']}"
      v == selected ? "0" : "1#{m['provider']}:#{m['label']}"
    end

    render json: { ok: true, models: models.first(limit) }
  end

  # PATCH /projects/:project_id/conversations/:id/set_model
  def set_model
    @conversation = @project.conversations.find(params[:id])

    selected = params.dig(:conversation, :selected_model).to_s
    if selected.blank?
      return render json: { ok: false, error: "missing_selected_model" }, status: :unprocessable_entity
    end

    provider, model = selected.split(":", 2)
    if provider.blank? || model.blank?
      return render json: { ok: false, error: "invalid_selected_model" }, status: :unprocessable_entity
    end

    @conversation.update!(pi_provider: provider, pi_model: model)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "model_picker",
          partial: "conversations/model_picker",
          locals: { project: @project, conversation: @conversation }
        )
      end
      format.html { redirect_to [@project, @conversation] }
    end
  end

  # DELETE /projects/:project_id/conversations/:id
  def destroy
    @conversation = @project.conversations.find(params[:id])
    @conversation.destroy!
    redirect_to @project, notice: "Conversation deleted"
  end

  # POST /projects/:project_id/conversations/:id/clear_messages
  def clear_messages
    @conversation = @project.conversations.find(params[:id])
    @conversation.messages.destroy_all
    redirect_to [@project, @conversation], notice: "Messages cleared"
  end

  # GET /projects/:project_id/conversations/:id/export
  def export
    @conversation = @project.conversations.find(params[:id])

    respond_to do |format|
      format.md do
        send_data generate_markdown_export(@conversation),
                  filename: "#{@conversation.title.parameterize}-#{Time.current.strftime('%Y%m%d-%H%M%S')}.md",
                  type: 'text/markdown',
                  disposition: 'attachment'
      end
    end
  end

  # POST /projects/:project_id/conversations/:id/archive
  def archive
    @conversation = @project.conversations.find(params[:id])
    @conversation.update!(archived: true, archived_at: Time.current)

    respond_to do |format|
      format.html { redirect_to @project, notice: "Chat archived" }
      format.turbo_stream { redirect_to @project, notice: "Chat archived" }
    end
  end

  # POST /projects/:project_id/conversations/:id/unarchive
  def unarchive
    @conversation = @project.conversations.find(params[:id])
    @conversation.update!(archived: false, archived_at: nil)

    respond_to do |format|
      format.html { redirect_to [@project, @conversation], notice: "Chat restored" }
      format.turbo_stream { redirect_to [@project, @conversation], notice: "Chat restored" }
    end
  end

  private

  def generate_markdown_export(conversation)
    markdown = String.new

    # Header
    markdown << "# #{conversation.title}\n\n"
    markdown << "**Project:** #{conversation.project.name}\n"
    markdown << "**Exported:** #{Time.current.strftime('%B %d, %Y at %I:%M %p')}\n"
    markdown << "**Messages:** #{conversation.messages.count}\n\n"

    # System prompt if present
    if conversation.system_prompt.present?
      markdown << "## System Prompt\n\n"
      markdown << "#{conversation.system_prompt}\n\n"
    end

    # Messages
    markdown << "## Conversation\n\n"

    conversation.messages.order(:created_at).each do |message|
      role = message.role.capitalize
      timestamp = message.created_at.strftime('%H:%M')

      markdown << "### #{role} (#{timestamp})\n\n"

      # Message content
      markdown << "#{message.content}\n\n"

      # Attachments if any
      if message.attachments.any?
        markdown << "**Attachments:**\n"
        message.attachments.each do |attachment|
          markdown << "- #{attachment.name} (#{attachment.content_type}, #{number_to_human_size(attachment.file_size)})\n"
        end
        markdown << "\n"
      end

      markdown << "---\n\n"
    end

    markdown
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def conversation_params
    params.fetch(:conversation, {}).permit(:title, :system_prompt)
  end
end
