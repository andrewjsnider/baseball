module Player::PitchingEligibility
  extend ActiveSupport::Concern

  def required_rest_days_for_pitches(pitches_thrown)
    pitches = pitches_thrown.to_i
    return 0 if pitches <= 20
    return 1 if pitches <= 35
    return 2 if pitches <= 50
    return 3 if pitches <= 65
    4
  end

  def last_pitching_day_before_game(game)
    pitch_appearances
      .joins(:game)
      .where("pitch_appearances.pitches_thrown IS NOT NULL AND pitch_appearances.pitches_thrown > 0")
      .where(
        "(games.date < ?) OR (games.date = ? AND games.id < ?)",
        game.date,
        game.date,
        game.id
      )
      .order("games.date DESC, games.id DESC")
      .limit(1)
      .pluck("games.date")
      .first
  end

  def pitches_thrown_on_date(date, before_game:)
    pitch_appearances
      .joins(:game)
      .where("games.date = ?", date)
      .where("pitch_appearances.pitches_thrown IS NOT NULL AND pitch_appearances.pitches_thrown > 0")
      .where(
        "(games.date < ?) OR (games.date = ? AND games.id < ?)",
        before_game.date,
        before_game.date,
        before_game.id
      )
      .sum(:pitches_thrown)
      .to_i
  end

  def next_eligible_pitching_date(before_game: nil, before_date: nil)
    if before_game.present?
      last_day = last_pitching_day_before_game(before_game)
      return nil if last_day.nil?

      day_total = pitches_thrown_on_date(last_day, before_game: before_game)
      rest_days = required_rest_days_for_pitches(day_total)

      return last_day + 1 + rest_days
    end

    last = last_pitch_appearance(before_date: before_date)
    return nil if last.nil?

    outing_date = last.game.date
    rest_days = required_rest_days_for_pitches(last.pitches_thrown)

    outing_date + 1 + rest_days
  end

  def eligible_to_pitch_on?(date, before_game: nil, before_date: nil)
    eligible_on = next_eligible_pitching_date(before_game: before_game, before_date: before_date)
    return true if eligible_on.nil?
    date >= eligible_on
  end

  def eligible_to_pitch_in_game?(game)
    eligible_to_pitch_on?(game.date, before_game: game)
  end

  def last_pitch_appearance(before_game: nil, before_date: nil)
    scope =
      pitch_appearances
        .joins(:game)
        .where("pitch_appearances.pitches_thrown IS NOT NULL AND pitch_appearances.pitches_thrown > 0")

    if before_game.present?
      scope =
        scope.where(
          "(games.date < ?) OR (games.date = ? AND games.id < ?)",
          before_game.date,
          before_game.date,
          before_game.id
        )
    elsif before_date.present?
      scope = scope.where("games.date < ?", before_date)
    end

    scope.order("games.date DESC, games.id DESC").first
  end
end