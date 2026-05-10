class AddParentIdToIndicators < ActiveRecord::Migration[8.1]
  def change
    add_reference :indicators, :parent, foreign_key: { to_table: :indicators }, index: true, null: true
  end
end
