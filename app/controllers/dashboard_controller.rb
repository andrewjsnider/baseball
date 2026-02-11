class DashboardController < ApplicationController
  def index
    @team = Team.first || Team.create!(name: "My Team")
    @teams_count = Team.count

    @available_players = Player.where(team_id: nil)

    @dropoffs = {}

    Position.pluck(:name).each do |position_name|
        @dropoffs[position_name] = Player.positional_dropoff(position_name)
    end

    @ranked_players = Player.where(team_id: nil)
                            .includes(:positions)
                            .sort_by { |p| -p.recommendation_score(@team, @dropoffs) }
  end
end
