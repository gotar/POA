class CreateKnowledgeSearches < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_searches do |t|
      t.string :query, null: false
      t.string :mode, null: false
      t.string :status, null: false, default: "queued"
      t.json :results
      t.text :error

      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :knowledge_searches, :created_at
    add_index :knowledge_searches, :status
  end
end
