class AddPitcherToLineups < ActiveRecord::Migration[8.0]
  def change
    add_column :lineups, :starting_pitcher_id, :integer
    add_column :lineups, :planned_pitch_limit, :integer
  end
end
