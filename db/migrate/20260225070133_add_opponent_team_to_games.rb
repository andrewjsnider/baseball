class AddOpponentTeamToGames < ActiveRecord::Migration[8.0]
  def change
      add_reference :games, :opponent_team, foreign_key: { to_table: :teams }, index: true
  end
end
