class CreateKnowledgeBases < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_bases do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.string :category
      t.text :tags

      t.timestamps
    end
  end
end
