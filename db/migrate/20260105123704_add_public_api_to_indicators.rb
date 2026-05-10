class AddPublicApiToIndicators < ActiveRecord::Migration[8.1]
  def change
    add_column :indicators, :public_api, :boolean, default: false, null: false
    add_index :indicators, :public_api
  end
end
