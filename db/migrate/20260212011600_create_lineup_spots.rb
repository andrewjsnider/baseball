class CreateLineupSpots < ActiveRecord::Migration[8.0]
  def change
    create_table :lineup_spots do |t|
      t.references :lineup, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :batting_order

      t.timestamps
    end
  end
end
