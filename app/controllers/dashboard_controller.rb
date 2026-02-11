class DashboardController < ApplicationController
  def index
    @team = Team.first || Team.create!(name: "My Team")

    @available_players = Player.where(team_id: nil)

    @ranked_players = Player.where(team_id: nil)
                         .includes(:positions)
                         .sort_by { |p| p.recommendation_score(@team) }
                         .reverse
  end
end
