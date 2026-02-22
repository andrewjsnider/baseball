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

  def export
    team = Team.first || Team.create!(name: "My Team")
    available = Player.where(team_id: nil).includes(:positions).to_a

    # Build the same supporting hashes your recommendation_score expects
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
        "Rank", "First", "Last", "Name", "Age", "Positions", "Tier",
        "INF(coach)", "OUT(coach)", "BAT(coach)", "PITCH(coach)", "Catch(coach)",
        "INF(asst)", "OUT(asst)", "BAT(asst)", "PITCH(asst)",
        "INF(avg)", "OUT(avg)", "BAT(avg)", "PITCH(avg)",
        "PCR H", "PCR F", "PCR T", "PCR P", "PCR TOTAL",
        "Rec", "Overall", "Manual Adj", "Notes"
      ]

      ranked.each_with_index do |p, i|
        out << [
          i + 1,
          p.first_name,
          p.last_name,
          p.name,
          p.age,
          p.positions.pluck(:name).join(", "),
          p.tier,
          p.infield_defense_rating,
          p.outfield_defense_rating,
          p.hitting_rating,
          p.pitching_rating,
          (p.can_catch ? "Y" : "N"),
          p.assistant_infield_defense_rating,
          p.assistant_outfield_defense_rating,
          p.assistant_hitting_rating,
          p.assistant_pitching_rating,
          p.agg_infield,
          p.agg_outfield,
          p.agg_bat,
          p.agg_pitch,
          p.pcr_hitting,
          p.pcr_fielding,
          p.pcr_throwing,
          p.pcr_pitching,
          p.pcr_total,
          p.recommendation_score(
            team,
            dropoffs: dropoffs,
            depths: position_depths,
            top_by_position: top_by_position,
            total_teams: Team.count
          ),
          p.overall_score,
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
