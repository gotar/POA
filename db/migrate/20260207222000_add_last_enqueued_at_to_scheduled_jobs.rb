class AddLastEnqueuedAtToScheduledJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :scheduled_jobs, :last_enqueued_at, :datetime
  end
end
