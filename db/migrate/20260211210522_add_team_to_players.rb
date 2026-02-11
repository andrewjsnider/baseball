class AddTeamToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_reference :players, :team, null: true, foreign_key: true
  end
end
