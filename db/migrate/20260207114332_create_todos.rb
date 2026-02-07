class CreateTodos < ActiveRecord::Migration[8.1]
  def change
    create_table :todos do |t|
      t.references :project, null: false, foreign_key: true
      t.text :content
      t.string :status
      t.integer :priority
      t.integer :position

      t.timestamps
    end
  end
end
