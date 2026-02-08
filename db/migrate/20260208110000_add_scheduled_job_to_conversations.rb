class AddScheduledJobToConversations < ActiveRecord::Migration[8.1]
  def change
    add_reference :conversations, :scheduled_job, null: true, foreign_key: true, index: true
  end
end
