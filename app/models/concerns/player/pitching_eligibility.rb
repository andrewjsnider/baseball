# app/models/concerns/player/pitching_eligibility.rb
module Player::PitchingEligibility
  extend ActiveSupport::Concern

  RestGate = Struct.new(:last_day, :day_total, :eligible_on, keyword_init: true)

  def required_rest_days_for_pitches(pitches_thrown)
    pitches = pitches_thrown.to_i
    return 0 if pitches <= 20
    return 1 if pitches <= 35
    return 2 if pitches <= 50
    return 3 if pitches <= 65
    4
  end

  # Returns a hash { Date => total_pitches_on_that_date } for all pitching days
  # prior to the given game (doubleheader-safe).
  def pitching_day_totals_before_game(game)
    pitch_appearances
      .joins(:game)
      .where("pitch_appearances.pitches_thrown IS NOT NULL AND pitch_appearances.pitches_thrown > 0")
      .where(
        "(games.date < ?) OR (games.date = ? AND games.id < ?)",
        game.date,
        game.date,
        game.id
      )
      .group("games.date")
      .sum(:pitches_thrown)
  end

  # Similar, but uses a cutoff date (for dashboards). Doubleheader does not matter here.
  def pitching_day_totals_before_date(date)
    pitch_appearances
      .joins(:game)
      .where("pitch_appearances.pitches_thrown IS NOT NULL AND pitch_appearances.pitches_thrown > 0")
      .where("games.date < ?", date)
      .group("games.date")
      .sum(:pitches_thrown)
  end

  # Core logic: pick the pitching day that produces the latest eligible_on date.
  def rest_gate_before_game(game)
    totals = pitching_day_totals_before_game(game)
    return nil if totals.blank?

    best = nil

    totals.each do |day, total|
      rest_days = required_rest_days_for_pitches(total)
      eligible_on = day + 1 + rest_days

      if best.nil? || eligible_on > best.eligible_on
        best = RestGate.new(last_day: day, day_total: total.to_i, eligible_on: eligible_on)
      end
    end

    best
  end

  def rest_gate_before_date(date)
    totals = pitching_day_totals_before_date(date)
    return nil if totals.blank?

    best = nil

    totals.each do |day, total|
      rest_days = required_rest_days_for_pitches(total)
      eligible_on = day + 1 + rest_days

      if best.nil? || eligible_on > best.eligible_on
        best = RestGate.new(last_day: day, day_total: total.to_i, eligible_on: eligible_on)
      end
    end

    best
  end

  def next_eligible_pitching_date(before_game: nil, before_date: nil)
    if before_game.present?
      gate = rest_gate_before_game(before_game)
      return nil if gate.nil?
      return gate.eligible_on
    end

    if before_date.present?
      gate = rest_gate_before_date(before_date)
      return nil if gate.nil?
      return gate.eligible_on
    end

    nil
  end

  def eligible_to_pitch_on?(date, before_game: nil, before_date: nil)
    eligible_on = next_eligible_pitching_date(before_game: before_game, before_date: before_date)
    return true if eligible_on.nil?
    date >= eligible_on
  end

  def eligible_to_pitch_in_game?(game)
    eligible_to_pitch_on?(game.date, before_game: game)
  end
end