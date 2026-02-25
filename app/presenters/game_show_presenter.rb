class GameShowPresenter
  PitcherRow = Struct.new(
    :player,
    :today_appearance,
    :today_pitches,
    :last_appearance,
    :last_date,
    :last_pitches,
    :rest_days,
    :eligible_on,
    :eligible_today,
    keyword_init: true
  )

  attr_reader :game, :opponent_team, :opponent_players

  def initialize(game:, opponent_team: nil, opponent_players: nil)
    @game = game
    @opponent_team = opponent_team
    @opponent_players = opponent_players || []
  end

  def opp_name
    game.opponent_team&.name || game.opponent
  end

  def game_date
    game.date
  end

  def has_lineup?
    game.lineup.present?
  end

  def required_positions
    @required_positions ||= LineupSlot.field_positions.keys - ["extra_hitter"]
  end

  def filled_positions
    return [] unless has_lineup?
    @filled_positions ||= game.lineup.lineup_slots.pluck(:field_position).compact
  end

  def missing_positions
    @missing_positions ||= required_positions - filled_positions
  end

  def starting_pitcher_slot
    return nil unless has_lineup?
    @starting_pitcher_slot ||= game.lineup.lineup_slots.pitcher.first
  end

  def my_pitchers
    @my_pitchers ||= game.team.players.select(&:can_pitch).sort_by { |p| -(p.agg_pitch.to_f) }
  end

  def pitch_appearances_today_by_player_id
    @pitch_appearances_today_by_player_id ||=
      PitchAppearance
        .where(game_id: game.id, player_id: my_pitchers.map(&:id))
        .index_by(&:player_id)
  end

  def last_prior_pitch_appearance_by_player_id
    return @last_prior_pitch_appearance_by_player_id if defined?(@last_prior_pitch_appearance_by_player_id)

    prior =
      PitchAppearance
        .joins(:game)
        .where(player_id: my_pitchers.map(&:id))
        .where("games.date < ?", game_date)
        .where("pitch_appearances.pitches_thrown IS NOT NULL AND pitch_appearances.pitches_thrown > 0")
        .order("games.date DESC")

    by_id = {}
    prior.each { |pa| by_id[pa.player_id] ||= pa }

    @last_prior_pitch_appearance_by_player_id = by_id
  end

  def pitcher_rows
    @pitcher_rows ||=
      my_pitchers.map do |p|
        today = pitch_appearances_today_by_player_id[p.id]
        today_pitches = today&.pitches_thrown.to_i

        last = last_prior_pitch_appearance_by_player_id[p.id]
        last_date = last&.game&.date
        last_pitches = last&.pitches_thrown.to_i

        rest_days = required_rest_days_for(last_pitches)

        eligible_on =
          if last_date.present?
            last_date + 1 + rest_days
          end

        eligible_today = eligible_on.nil? || game_date >= eligible_on

        PitcherRow.new(
          player: p,
          today_appearance: today,
          today_pitches: today_pitches,
          last_appearance: last,
          last_date: last_date,
          last_pitches: last_pitches,
          rest_days: rest_days,
          eligible_on: eligible_on,
          eligible_today: eligible_today
        )
      end
  end

  def required_rest_days_for(pitches_thrown)
    pitches = pitches_thrown.to_i
    return 0 if pitches <= 20
    return 1 if pitches <= 35
    return 2 if pitches <= 50
    return 3 if pitches <= 65
    4
  end

  def pitch_plan_slots
    game.ensure_pitch_plan_slots!
    @pitch_plan_slots ||= game.game_pitch_plan_slots.order(:role).includes(:player)
  end

  def eligible_pitchers_for_game
    pitcher_rows.select(&:eligible_today).map(&:player)
  end

  def projected_next_eligible_date(player, target_pitches)
    return nil if player.nil?
    return nil if target_pitches.to_i <= 0

    rest_days = required_rest_days_for(target_pitches)
    game_date + 1 + rest_days
  end

  def scouting_report
    @scouting_report ||= ScoutingReportPresenter.new(
      game: game,
      opponent_team: opponent_team,
      opponent_players: opponent_players
    )
  end

  def opponent_team
    @opponent_team ||= game.opponent_team
  end

  def opponent_players
    return [] unless opponent_team.present?
    @opponent_players ||= opponent_team.players.to_a
  end
end