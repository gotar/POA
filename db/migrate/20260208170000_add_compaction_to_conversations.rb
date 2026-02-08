# frozen_string_literal: true

class AddCompactionToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :compacted_summary, :text
    add_column :conversations, :compacted_until_message_id, :integer
    add_column :conversations, :compacted_at, :datetime

    add_index :conversations, :compacted_until_message_id
  end
end
