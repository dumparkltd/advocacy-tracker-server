class AddOfficialToMeasures < ActiveRecord::Migration[8.1]
  def change
    add_column :measures, :is_official, :boolean, default: false
  end
end
