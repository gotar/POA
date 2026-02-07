# frozen_string_literal: true

class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:push_subscriptions)
      create_table :push_subscriptions do |t|
        t.references :project, null: true, foreign_key: true
        t.string :endpoint, null: false
        t.string :p256dh, null: false
        t.string :auth, null: false
        t.string :user_agent

        t.timestamps
      end
    end

    add_index :push_subscriptions, :endpoint, unique: true unless index_exists?(:push_subscriptions, :endpoint, unique: true)
    add_index :push_subscriptions, :project_id unless index_exists?(:push_subscriptions, :project_id)
  end
end
