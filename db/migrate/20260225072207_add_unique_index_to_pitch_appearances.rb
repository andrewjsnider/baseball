class AddUniqueIndexToPitchAppearances < ActiveRecord::Migration[8.0]
  def change
    add_index :pitch_appearances, [:game_id, :player_id], unique: true
  end
end
