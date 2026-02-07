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
        format.html { redirect_to [@project, @conversation] }
      end
    else
      respond_to do |format|
        format.turbo_stream { render_error }
        format.html { redirect_to [@project, @conversation], alert: "Failed to create message" }
      end
    end
  end

  # POST /projects/:project_id/conversations/:id/stream
  def stream
    response.content_type = "text/vnd.turbo-stream.html"

    process_conversation_stream do |event|
      response.stream.write(render_event(event))
    end
  ensure
    response.stream.close
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

  def process_with_pi
    # Start streaming response with placeholder content
    @assistant_message = @conversation.messages.create!(role: "assistant", content: "")

    # Render the user message immediately
    render turbo_stream: [
      turbo_stream.append("messages", partial: "messages/message", locals: { message: @message }),
      turbo_stream.append("messages", partial: "messages/message", locals: { message: @assistant_message }),
      turbo_stream.update("message_form", partial: "messages/form", locals: { project: @project, conversation: @conversation, message: @conversation.messages.build(role: "user") })
    ]

    # Process in background job for streaming
    PiStreamJob.perform_later(
      @conversation.id,
      @assistant_message.id,
      @project.id,
      @conversation.pi_provider,
      @conversation.pi_model
    )
  end

  def process_conversation_stream
    pi = pi_service

    # Build context from project notes and todos
    context = build_project_context

    # Build message with context
    full_message = context.present? ? "#{context}\n\nUser: #{@message.content}" : @message.content

    pi.prompt(full_message) do |event|
      yield event
    end
  rescue PiRpcService::Error => e
    Rails.logger.error "Pi RPC error: #{e.message}"
    yield({ type: "error", message: e.message })
  end

  def build_project_context
    return nil unless @project

    parts = []

    # Add context notes
    if @project.context_notes.any?
      parts << "## Project Context"
      parts += @project.context_notes.map(&:to_context_string)
    end

    # Add knowledge base items (context and reference categories)
    knowledge_context = @project.knowledge_bases.where(category: %w[context reference]).limit(5)
    if knowledge_context.any?
      parts << "## Knowledge Base"
      knowledge_context.each do |kb|
        parts << "### #{kb.title}"
        parts << kb.content.truncate(500)
      end
    end

    # Add active todos
    if @project.active_todos.any?
      parts << "## Active TODOs"
      parts += @project.active_todos.map { |t| "- #{t.status.upcase}: #{t.content}" }
    end

    parts.join("\n\n").presence
  end

  def render_event(event)
    case event["type"]
    when "text_delta"
      @assistant_message.update(content: @assistant_message.content + event["delta"])
      turbo_stream.replace("message_#{@assistant_message.id}", partial: "messages/message", locals: { message: @assistant_message })
    when "tool_use"
      turbo_stream.append("message_#{@assistant_message.id}_tools", partial: "messages/tool_use", locals: { tool: event })
    when "response"
      turbo_stream.replace("message_#{@assistant_message.id}", partial: "messages/message", locals: { message: @assistant_message })
    else
      ""
    end
  end

  def render_error
    render turbo_stream: turbo_stream.append("messages", partial: "shared/error", locals: { message: "Failed to send message" })
  end

  def pi_service
    @pi_service ||= PiRpcService.new.tap(&:start)
  end
end
