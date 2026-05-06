class AddHasPrecedenceToMeasures < ActiveRecord::Migration[8.1]
  def change
    add_column :measures, :has_precedence, :boolean
  end
end
