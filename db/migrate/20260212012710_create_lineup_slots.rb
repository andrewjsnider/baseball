class CreateLineupSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :lineup_slots do |t|
      t.references :lineup, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.integer :batting_order
      t.integer :field_position

      t.timestamps
    end
  end
end
