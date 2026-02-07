# frozen_string_literal: true

class ConversationsController < ApplicationController
  before_action :set_project

  # GET /projects/:project_id/conversations
  def index
    @conversations = @project.conversations.recent
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
    params.expect(conversation: %i[title system_prompt])
  end
end
