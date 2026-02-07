class CreateRuntimeMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :runtime_metrics do |t|
      t.string :key, null: false
      t.text :value

      t.timestamps
    end

    add_index :runtime_metrics, :key, unique: true
  end
end
