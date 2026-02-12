class AddClubTeamToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :club_team, :boolean, default: false, null: true
  end
end
