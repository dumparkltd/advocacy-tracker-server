class AddPublicApiFieldsToIndicators < ActiveRecord::Migration[8.1]
  def change
    add_column :indicators, :teaser_api, :text
    add_column :indicators, :annotation_api, :text
    add_column :indicators, :short_api, :text
  end
end
