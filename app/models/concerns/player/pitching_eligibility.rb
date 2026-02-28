module Player::PitchingEligibility
  extend ActiveSupport::Concern

  DAILY_MAX_PITCHES = 85

  RestGate = Struct.new(:last_day, :day_total, :eligible_on, keyword_init: true)

  def required_rest_days_for_pitches(pitches_thrown)
    pitches = pitches_thrown.to_i
    return 0 if pitches <= 20
    return 1 if pitches <= 35
    return 2 if pitches <= 50
    return 3 if pitches <= 65
    4
  end

  def pitching_day_totals_before_game(game)
    pitch_appearances
      .with_pitches
      .where(
        "(pitch_appearances.pitched_on < ?) OR (pitch_appearances.pitched_on = ? AND pitch_appearances.game_id < ?)",
        game.date,
        game.date,
        game.id
      )
      .group(:pitched_on)
      .sum(:pitches_thrown)
  end

  def pitching_day_totals_before_date(date)
    pitch_appearances
      .with_pitches
      .where("pitch_appearances.pitched_on < ?", date)
      .group(:pitched_on)
      .sum(:pitches_thrown)
  end

  def rest_gate_before_game(game)
    totals = pitching_day_totals_before_game(game)
    rest_gate_from_totals(totals)
  end

  def rest_gate_before_date(date)
    totals = pitching_day_totals_before_date(date)
    rest_gate_from_totals(totals)
  end

  def rest_gate_from_totals(totals)
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
    gate =
      if before_game.present?
        rest_gate_before_game(before_game)
      elsif before_date.present?
        rest_gate_before_date(before_date)
      end

    gate&.eligible_on
  end

  def eligible_to_pitch_on?(date, before_game: nil, before_date: nil)
    eligible_on = next_eligible_pitching_date(before_game: before_game, before_date: before_date)
    return true if eligible_on.nil?
    date >= eligible_on
  end

  def pitches_thrown_on_date(date)
    pitch_appearances
      .with_pitches
      .where(pitched_on: date)
      .sum(:pitches_thrown)
      .to_i
  end

  def remaining_pitches_on_date(date)
    remaining = DAILY_MAX_PITCHES - pitches_thrown_on_date(date)
    remaining.positive? ? remaining : 0
  end

  def eligible_to_pitch_in_game?(game)
    return false unless eligible_to_pitch_on?(game.date, before_game: game)
    remaining_pitches_on_date(game.date) > 0
  end

  def removed_as_pitcher_in_game?(game, on_date: nil)
    scope = pitch_appearances.where(game_id: game.id)
    scope = scope.where(pitched_on: on_date) if on_date.present?
    scope.where(removed_from_mound: true).exists?
  end
end
