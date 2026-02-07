class CreateScheduledJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_jobs do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name
      t.string :cron_expression
      t.text :prompt_template
      t.boolean :active
      t.string :status
      t.datetime :last_run_at
      t.datetime :next_run_at

      t.timestamps
    end
  end
end
