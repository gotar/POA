class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.string :category

      t.timestamps
    end
  end
end
