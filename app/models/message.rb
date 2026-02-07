class Message < ApplicationRecord
  belongs_to :conversation

  has_many :attachments, as: :attachable, dependent: :destroy

  validates :role, presence: true, inclusion: { in: %w[user assistant system] }
  validates :content, presence: true

  # Convert to format expected by pi RPC
  def to_rpc_format
    {
      role: role,
      content: content
    }
  end
end
