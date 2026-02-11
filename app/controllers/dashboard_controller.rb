class DashboardController < ApplicationController
  def index
    @team = Team.first || Team.create!(name: "My Team")
    @teams_count = Team.count

    @available_players = Player.where(team_id: nil)

    available = Player.where(team_id: nil).includes(:positions).to_a

    @position_depths = Hash.new(0)
    @top_by_position = {}
    @dropoffs = {}

    Position.pluck(:name).each do |pos_name|
      players_for_pos = available.select { |p| p.plays_position?(pos_name) }
      sorted = players_for_pos.sort_by { |p| -p.overall_score }

      @position_depths[pos_name] = sorted.size
      @top_by_position[pos_name] = sorted.first
      @dropoffs[pos_name] =
        if sorted.size >= 2
          sorted[0].overall_score - sorted[1].overall_score
        else
          0
        end
    end

    @ranked_players = available.sort_by do |player|
      -player.recommendation_score(
        @team,
        dropoffs: @dropoffs,
        depths: @position_depths,
        top_by_position: @top_by_position,
        total_teams: Team.count
      )
    end
  end
end
