# frozen_string_literal: true

# Coordinates conversation message processing so only one PiStreamJob runs per conversation.
# If a user sends a new message while a run is in progress, it is queued.
class ConversationQueueService
  Result = Struct.new(:queued, :assistant_message, keyword_init: true)

  def self.enqueue_user_message!(conversation:, user_message:, project_id:, pi_provider:, pi_model:)
    conversation.with_lock do
      if conversation.processing?
        user_message.update!(status: "queued")
        return Result.new(queued: true)
      end

      conversation.update!(processing: true, processing_started_at: Time.current)

      # The message is already persisted at this point, so it's effectively "sent".
      # We only use `status` for queueing (queued vs not queued).
      user_message.update!(status: "done")

      assistant_message = conversation.messages.create!(role: "assistant", content: "", status: "running")

      PiStreamJob.perform_later(
        conversation.id,
        assistant_message.id,
        project_id,
        pi_provider,
        pi_model,
        user_message.id
      )

      Result.new(queued: false, assistant_message: assistant_message)
    end
  end
end
