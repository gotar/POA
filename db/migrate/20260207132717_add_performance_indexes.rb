class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Index for todo status and ordering (frequently queried)
    add_index :todos, [:project_id, :status] unless index_exists?(:todos, [:project_id, :status])
    add_index :todos, [:project_id, :position] unless index_exists?(:todos, [:project_id, :position])

    # Index for knowledge base category searches
    add_index :knowledge_bases, [:project_id, :category] unless index_exists?(:knowledge_bases, [:project_id, :category])

    # Index for scheduled job status and next_run_at
    add_index :scheduled_jobs, :status unless index_exists?(:scheduled_jobs, :status)
    add_index :scheduled_jobs, :next_run_at unless index_exists?(:scheduled_jobs, :next_run_at)
    add_index :scheduled_jobs, [:project_id, :active] unless index_exists?(:scheduled_jobs, [:project_id, :active])

    # Index for updated_at ordering (used in recent scopes)
    add_index :conversations, :updated_at unless index_exists?(:conversations, :updated_at)
    add_index :todos, :updated_at unless index_exists?(:todos, :updated_at)
    add_index :notes, :updated_at unless index_exists?(:notes, :updated_at)
    add_index :knowledge_bases, :updated_at unless index_exists?(:knowledge_bases, :updated_at)

    # Composite index for active todos query
    add_index :todos, [:project_id, :status, :position] unless index_exists?(:todos, [:project_id, :status, :position])
  end
end
