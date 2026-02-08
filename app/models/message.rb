class Message < ApplicationRecord
  belongs_to :conversation

  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :tool_calls, class_name: "MessageToolCall", dependent: :destroy

  STATUSES = %w[done running queued error].freeze

  validates :role, presence: true, inclusion: { in: %w[user assistant system] }
  validates :status, presence: true, inclusion: { in: STATUSES }

  # Assistant messages are created as placeholders while streaming, so content may be blank initially.
  validates :content, presence: true, unless: -> { role == "assistant" }

  # Convert to format expected by pi RPC
  def to_rpc_format
    {
      role: role,
      content: content
    }
  end
end
