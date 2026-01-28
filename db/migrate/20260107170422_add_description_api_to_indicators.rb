class AddDescriptionApiToIndicators < ActiveRecord::Migration[8.1]
  def change
    add_column :indicators, :description_api, :text
  end
end
