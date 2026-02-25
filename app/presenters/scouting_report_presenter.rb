class ScoutingReportPresenter
  attr_reader :game, :opponent_team, :opponent_players

  def initialize(game:, opponent_team:, opponent_players:)
    @game = game
    @opponent_team = opponent_team
    @opponent_players = Array(opponent_players)
  end

  def opp_name
    game.opponent_team&.name || game.opponent
  end

  def opponent_linked?
    opponent_team.present?
  end

  def opponent_has_players?
    opponent_players.any?
  end

  def players_count
    opponent_players.size
  end

  def pitcher_score
    average(nonzero_values(opponent_players.map { |p| p.agg_pitch.to_f }))
  end

  def offensive_score
    average(nonzero_values(opponent_players.map { |p| p.agg_bat.to_f }))
  end

  def defensive_score
    average(defense_values(opponent_players))
  end

  def top_offense(limit: 5)
    opponent_players
      .sort_by { |p| -(p.agg_bat.to_f) }
      .first(limit)
      .map { |p| player_row(p, :offense) }
  end

  def top_pitching(limit: 5)
    opponent_players
      .select(&:can_pitch)
      .sort_by { |p| -(p.agg_pitch.to_f) }
      .first(limit)
      .map { |p| player_row(p, :pitching) }
  end

  def top_defense(limit: 5)
    opponent_players
      .sort_by { |p| -(player_def_score(p).to_f) }
      .first(limit)
      .map { |p| player_row(p, :defense) }
  end

  def opponent_roster_link?
    opponent_linked? && game.opponent_team.present?
  end

  private

  def nonzero_values(vals)
    vals.reject(&:zero?)
  end

  def average(vals)
    return nil if vals.empty?
    vals.sum / vals.size.to_f
  end

  def defense_values(players)
    players.map { |p| player_def_score(p) }.compact
  end

  def player_def_score(p)
    inf = p.agg_infield.to_f
    outf = p.agg_outfield.to_f

    return nil if inf.zero? && outf.zero?

    if inf.positive? && outf.positive?
      (inf + outf) / 2.0
    else
      inf.positive? ? inf : outf
    end
  end

  def player_row(player, kind)
    score =
      case kind
      when :offense then player.agg_bat.to_f
      when :pitching then player.agg_pitch.to_f
      when :defense then player_def_score(player).to_f
      end

    { player: player, score: score }
  end
end