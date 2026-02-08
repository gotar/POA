# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_project
  before_action :set_conversation

  # POST /projects/:project_id/conversations/:conversation_id/messages
  def create
    @message = @conversation.messages.build(message_params)
    @message.role = "user"

    # Handle file attachments
    if params[:message][:attachments].present?
      params[:message][:attachments].each do |attachment_data|
        next unless attachment_data[:file].present?
        attachment = @message.attachments.build(
          name: attachment_data[:name] || File.basename(attachment_data[:file].original_filename),
          file: attachment_data[:file]
        )
      end
    end

    if @message.save
      # Generate title from first message if needed
      @conversation.generate_title_from_first_message!

      respond_to do |format|
        format.turbo_stream { process_with_pi }
        format.html do
          enqueue_with_pi
          redirect_to [@project, @conversation]
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render_error }
        format.html { redirect_to [@project, @conversation], alert: "Failed to create message" }
      end
    end
  end


  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_conversation
    @conversation = @project.conversations.find(params[:conversation_id])
  end

  def message_params
    params.expect(message: %i[content])
  end

  def enqueue_with_pi
    # Ensure conversation has a default model selection so subsequent jobs are deterministic.
    if @conversation.pi_provider.blank? || @conversation.pi_model.blank?
      defaults = PiModelsService.default_provider_model
      @conversation.update_columns(pi_provider: defaults[:provider], pi_model: defaults[:model])
    end

    ConversationQueueService.enqueue_user_message!(
      conversation: @conversation,
      user_message: @message,
      project_id: @project.id,
      pi_provider: @conversation.pi_provider,
      pi_model: @conversation.pi_model
    )
  end

  def process_with_pi
    result = enqueue_with_pi

    streams = [
      turbo_stream.append("messages", partial: "messages/message", locals: { message: @message })
    ]

    # Only append an assistant placeholder if we actually started processing now.
    if result.queued
      # User sent a follow-up while the agent is still working.
      # The queued badge is rendered from message.status.
      streams << turbo_stream.replace("message_#{@message.id}", partial: "messages/message", locals: { message: @message.reload })
    else
      streams << turbo_stream.append("messages", partial: "messages/message", locals: { message: result.assistant_message })
    end

    streams << turbo_stream.update(
      "message_form",
      partial: "messages/form",
      locals: { project: @project, conversation: @conversation, message: @conversation.messages.build(role: "user") }
    )

    render turbo_stream: streams
  end


  def render_error
    render turbo_stream: turbo_stream.append("messages", partial: "shared/error", locals: { message: "Failed to send message" })
  end

end
