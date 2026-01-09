class AddCodeApiToIndicators < ActiveRecord::Migration[8.1]
  def change
    add_column :indicators, :code_api, :string
  end
end
