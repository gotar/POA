# frozen_string_literal: true

class CreateHeartbeatEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :heartbeat_events do |t|
      t.datetime :started_at, null: false
      t.integer :duration_ms
      t.string :status, null: false
      t.text :alerts_json

      t.string :agent_status
      t.string :agent_provider
      t.string :agent_model
      t.text :agent_message
      t.text :agent_error

      t.integer :stuck_conversations_fixed
      t.integer :stuck_messages_fixed
      t.integer :stuck_tool_calls_fixed

      t.timestamps
    end

    add_index :heartbeat_events, :started_at
    add_index :heartbeat_events, :status
  end
end
