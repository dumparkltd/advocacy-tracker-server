class AddPublicApiToMeasures < ActiveRecord::Migration[8.1]
  def change
    add_column :measures, :public_api, :boolean, default: false, null: false
    add_index :measures, :public_api
  end
end
