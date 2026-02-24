require 'CSV'

class DashboardController < ApplicationController
  def index
    @team = Team.first || Team.create!(name: "My Team")
    @teams_count = Team.count

    @available_players = Player.where(team_id: nil)
    @limited_info_player_ids = @available_players.eval_fields_filled_count_lt(2).pluck(:id).to_set

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

  def export
    team = Team.first || Team.create!(name: "My Team")
    available = Player.where(team_id: nil).includes(:positions).to_a

    position_depths = Hash.new(0)
    top_by_position = {}
    dropoffs = {}

    Position.pluck(:name).each do |pos_name|
      players_for_pos = available.select { |p| p.plays_position?(pos_name) }
      sorted = players_for_pos.sort_by { |p| -p.overall_score.to_f }

      position_depths[pos_name] = sorted.size
      top_by_position[pos_name] = sorted.first
      dropoffs[pos_name] =
        if sorted.size >= 2
          sorted[0].overall_score.to_f - sorted[1].overall_score.to_f
        else
          0
        end
    end

    ranked = available.sort_by do |player|
      -player.recommendation_score(
        team,
        dropoffs: dropoffs,
        depths: position_depths,
        top_by_position: top_by_position,
        total_teams: Team.count
      )
    end

    csv = CSV.generate(headers: true) do |out|
      out << [
        "Rank",
        "PCR ID",
        "Name",
        "Age",
        "Positions",
        "Tier",
        "Rec",
        "Overall",
        "BAT",
        "INF",
        "OUT",
        "PITCH",
        "Catch?",
        "PCR TOTAL",
        "Manual Adj",
        "Notes"
      ]

      ranked.each_with_index do |p, i|
        rec = p.recommendation_score(
          team,
          dropoffs: dropoffs,
          depths: position_depths,
          top_by_position: top_by_position,
          total_teams: Team.count
        )

        out << [
          i + 1,
          (p.respond_to?(:pcr_id) ? p.pcr_id : p.try(:pcr_player_id) || p.try(:pcr_identifier)),
          p.name, # keep just one name column
          p.age,
          p.positions.map(&:name).join(", "),
          p.tier,
          rec,
          p.overall_score,
          p.hitting_rating,
          p.infield_defense_rating,
          p.outfield_defense_rating,
          p.pitching_rating,
          (p.can_catch ? "Y" : "N"),
          p.pcr_total,
          p.manual_adjustment,
          p.notes
        ]
      end
    end

    send_data csv,
      filename: "draft_board_#{Date.current}.csv",
      type: "text/csv"
  end
end
