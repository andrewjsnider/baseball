class CreatePlayerDays < ActiveRecord::Migration[8.0]
  def change
    create_table :player_days do |t|
      t.references :player, null: false, foreign_key: true
      t.date :date, null: false
      t.boolean :caught_any, null: false, default: false

      t.timestamps
    end

    add_index :player_days, [:player_id, :date], unique: true
    add_index :player_days, :date
  end
end
