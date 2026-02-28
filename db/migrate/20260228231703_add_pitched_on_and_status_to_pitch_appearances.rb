class AddPitchedOnAndStatusToPitchAppearances < ActiveRecord::Migration[8.0]
  def up
    add_column :pitch_appearances, :pitched_on, :date
    add_column :pitch_appearances, :removed_from_mound, :boolean, null: false, default: false
    add_column :pitch_appearances, :ended_at, :datetime

    execute <<~SQL
      UPDATE pitch_appearances
      SET pitched_on = games.date
      FROM games
      WHERE pitch_appearances.game_id = games.id
        AND pitch_appearances.pitched_on IS NULL
    SQL

    change_column_null :pitch_appearances, :pitched_on, false

    remove_index :pitch_appearances, name: "index_pitch_appearances_on_game_id_and_player_id"
    add_index :pitch_appearances, [:game_id, :player_id, :pitched_on],
              unique: true,
              name: "index_pitch_appearances_on_game_id_player_id_pitched_on"
  end

  def down
    remove_index :pitch_appearances, name: "index_pitch_appearances_on_game_id_player_id_pitched_on"
    add_index :pitch_appearances, [:game_id, :player_id],
              unique: true,
              name: "index_pitch_appearances_on_game_id_and_player_id"

    remove_column :pitch_appearances, :ended_at
    remove_column :pitch_appearances, :removed_from_mound
    remove_column :pitch_appearances, :pitched_on
  end
end
