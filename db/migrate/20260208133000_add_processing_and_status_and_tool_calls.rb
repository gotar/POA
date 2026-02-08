# frozen_string_literal: true

class AddProcessingAndStatusAndToolCalls < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :processing, :boolean, null: false, default: false
    add_column :conversations, :processing_started_at, :datetime

    add_column :messages, :status, :string, null: false, default: "done"
    add_index :messages, :status

    create_table :message_tool_calls do |t|
      t.references :message, null: false, foreign_key: true
      t.string :tool_call_id, null: false
      t.string :tool_name, null: false
      t.json :args
      t.string :status, null: false, default: "running" # running|done|error
      t.boolean :is_error, null: false, default: false
      t.text :output_text
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    add_index :message_tool_calls, %i[message_id tool_call_id], unique: true
    add_index :message_tool_calls, :tool_call_id
  end
end
