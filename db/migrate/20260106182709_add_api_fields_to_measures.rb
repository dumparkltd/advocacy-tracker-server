class AddApiFieldsToMeasures < ActiveRecord::Migration[8.1]
  def change
    add_column :measures, :quote_api, :text
    add_column :measures, :source_api, :text
  end
end
