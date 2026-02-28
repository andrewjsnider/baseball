class InSeasonDashboardPresenter
  NextUpRow = Struct.new(:player, :eligible_on, keyword_init: true)

  attr_reader :team, :today, :next_game, :upcoming_games, :recent_games

  def initialize(team:, today:, next_game:, upcoming_games:, recent_games:)
    @team = team
    @today = today
    @next_game = next_game
    @upcoming_games = upcoming_games
    @recent_games = recent_games
  end

  def roster
    @roster ||= Player.where(team: team)
  end

  def pitchers
    @pitchers ||= roster.select(&:pitch_candidate?)
  end

  def eligible_pitchers
    @eligible_pitchers ||= pitchers.select { |p| p.eligible_to_pitch_on?(today, before_date: today) }
  end

  def resting_pitchers
    @resting_pitchers ||= pitchers - eligible_pitchers
  end

  def next_up_rows(limit: 3)
    resting_pitchers
      .map { |p| NextUpRow.new(player: p, eligible_on: p.next_eligible_pitching_date(before_date: today)) }
      .select { |r| r.eligible_on.present? }
      .sort_by(&:eligible_on)
      .first(limit)
  end

  def probable_starter
    return nil unless next_game&.lineup.present?
    next_game.lineup.lineup_slots.pitcher.first&.player
  end

  def probable_starter_name
    probable_starter&.name
  end
end