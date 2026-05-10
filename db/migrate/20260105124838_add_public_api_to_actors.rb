class AddPublicApiToActors < ActiveRecord::Migration[8.1]
  def change
    add_column :actors, :public_api, :boolean, default: false, null: false
    add_index :actors, :public_api
  end
end
