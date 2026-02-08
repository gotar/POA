# frozen_string_literal: true

class AddArchivedToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :archived, :boolean, null: false, default: false
    add_column :conversations, :archived_at, :datetime

    add_index :conversations, :archived
    add_index :conversations, %i[project_id archived updated_at]
  end
end
