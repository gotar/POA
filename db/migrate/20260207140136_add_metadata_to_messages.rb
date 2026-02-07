class AddMetadataToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :metadata, :json
  end
end
