# frozen_string_literal: true

class AddPiModelToScheduledJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :scheduled_jobs, :pi_provider, :string
    add_column :scheduled_jobs, :pi_model, :string

    add_index :scheduled_jobs, :pi_provider
    add_index :scheduled_jobs, :pi_model
  end
end
