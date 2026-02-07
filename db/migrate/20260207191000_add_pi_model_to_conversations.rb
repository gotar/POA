# frozen_string_literal: true

class AddPiModelToConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :pi_provider, :string
    add_column :conversations, :pi_model, :string

    add_index :conversations, :pi_provider
    add_index :conversations, :pi_model
  end
end
