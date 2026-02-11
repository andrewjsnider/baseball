class DashboardController < ApplicationController
  def index
    @team = Team.first || Team.create!(name: "My Team")

    @available_players = Player.where(team_id: nil)

    @ranked_players = @available_players.sort_by do |player|
        player.recommendation_score(@team)
    end.reverse
  end
end
