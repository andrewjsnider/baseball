class Player < ApplicationRecord
  TIERS = %w[A B C].freeze

  belongs_to :team, optional: true
  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  validates :name, presence: true
  validates :tier, inclusion: { in: TIERS }, allow_nil: true

  validates :pitching_rating,
            :hitting_rating,
            :infield_defense_rating,
            :outfield_defense_rating,
            :catching_rating,
            :baseball_iq,
            :athleticism,
            :confidence_level,
            numericality: { only_integer: true, in: 1..5 },
            allow_nil: true

  def recommendation_score(team, dropoffs: {}, depths: {}, top_by_position: {}, total_teams: Team.count)
    score = overall_score.to_f

    score += confidence_adjustment
    score += stale_adjustment
    score += age_adjustment(team)
    score += expected_availability_bonus(team, depths, total_teams)
    score += positional_cliff_bonus(dropoffs, top_by_position)
    score += pitching_bonus(team)
    score += catcher_bonus(team)
    score += middle_infield_bonus(team)
    score += risk_adjustment(team)
    score += flexibility_bonus(team)
    score += manual_adjustment.to_i

    score.round(1)
  end

  def computed_tier
    players = Player.all.to_a
    return nil if players.size < 5

    sorted = players.sort_by { |p| -p.overall_score.to_f }
    index = sorted.index(self)
    return nil unless index

    percentile = index.to_f / sorted.size

    if percentile <= 0.15
      "A"
    elsif percentile <= 0.35
      "B"
    else
      "C"
    end
  end

  def confidence_multiplier
    return 0.85 unless confidence_level.present?

    case confidence_level
    when 1 then 0.60
    when 2 then 0.75
    when 3 then 0.85
    when 4 then 0.93
    when 5 then 1.00
    else 0.85
    end
  end

  def effective_value(raw)
    return nil if raw.nil?
    raw.to_f * confidence_multiplier
  end

  def effective_pitching_rating
    effective_value(pitching_rating)
  end

  def effective_hitting_rating
    effective_value(hitting_rating)
  end

  def effective_infield_defense_rating
    effective_value(infield_defense_rating)
  end

  def effective_outfield_defense_rating
    effective_value(outfield_defense_rating)
  end

  def effective_catching_rating
    effective_value(catching_rating)
  end

  def effective_athleticism
    effective_value(athleticism)
  end

  def effective_baseball_iq
    effective_value(baseball_iq)
  end

  def uses_ratings_card?
    pitching_rating.present? ||
      hitting_rating.present? ||
      infield_defense_rating.present? ||
      outfield_defense_rating.present? ||
      catching_rating.present? ||
      athleticism.present?
  end

  def ratings_overall_score
    p = effective_pitching_rating.to_f
    c = effective_catching_rating.to_f
    i = effective_infield_defense_rating.to_f
    o = effective_outfield_defense_rating.to_f
    h = effective_hitting_rating.to_f
    a = effective_athleticism.to_f
    iq = effective_baseball_iq.to_f
    spd = effective_value(speed).to_f

    (p * 4.0) +
      (c * 3.0) +
      (i * 2.5) +
      (h * 2.0) +
      (a * 2.0) +
      (iq * 1.5) +
      (spd * 1.5) +
      (o * 1.0)
  end

  def legacy_overall_score
    pitcher_score +
      defensive_score +
      offensive_score +
      reliability_score
  end

  def overall_score
    score = uses_ratings_card? ? ratings_overall_score : legacy_overall_score
    score.round(1)
  end

  def confidence_adjustment
    return 0 unless confidence_level.present?
    -(5 - confidence_level) * 2.0
  end

  def stale_adjustment
    evaluation_stale? ? -(overall_score.to_f * 0.08) : 0
  end

  def age_adjustment(team)
    return 0 unless age == 12
    team.spots_remaining > 6 ? 4 : 2
  end

  def expected_availability_bonus(team, depths, total_teams)
    bonus = 0
    positions.each do |position|
      depth = depths[position.name] || 0
      if depth <= team.picks_until_next_turn(total_teams)
        bonus += 8
      end
    end
    bonus
  end

  def positional_cliff_bonus(dropoffs, top_by_position)
    bonus = 0
    positions.each do |position|
      next unless top_by_position[position.name] == self
      dropoff = dropoffs[position.name] || 0
      bonus += 10 if dropoff > 15
      bonus += 5 if dropoff > 8 && dropoff <= 15
    end
    bonus
  end

  def pitch_candidate?
    can_pitch || plays_position?("P") || pitching_rating.to_i >= 3
  end

  def catch_candidate?
    can_catch || plays_position?("C") || catching_rating.to_i >= 3
  end

  def pitching_bonus(team)
    return 0 unless pitch_candidate?

    need = team.pitchers_needed
    return 0 if need <= 0

    base = need >= 2 ? 26 : 14

    quality =
      if uses_ratings_card?
        (effective_pitching_rating.to_f / 5.0)
      else
        (pitcher_score.to_f / max_pitcher_score)
      end

    base * quality
  end

  def catcher_bonus(team)
    return 0 unless catch_candidate?
    return 0 if team.catchers_needed <= 0

    16
  end

  def middle_infield_bonus(team)
    return 0 unless plays_position?("SS") || plays_position?("2B")
    return 0 if team.middle_infield_needed <= 0

    team.middle_infield_needed >= 1 ? 12 : 6
  end

  def risk_adjustment(team)
    return 0 unless risk_flag
    team.spots_remaining > 6 ? -12 : -4
  end

  def flexibility_bonus(team)
    flex = positions.count
    return 0 if flex <= 1

    if team.spots_remaining <= 3
      flex * 3
    else
      flex * 2
    end
  end

  def evaluation_stale?
    return true if evaluation_date.nil?
    evaluation_date < 1.year.ago
  end

  def plays_position?(name)
    positions.any? { |p| p.name == name }
  end

  def pitcher_score
    pitching_control.to_i * 2 +
      pitching_velocity.to_i +
      arm_strength.to_i +
      baseball_iq.to_i
  end

  def max_pitcher_score
    20.0
  end

  def defensive_score
    fielding.to_i +
      arm_accuracy.to_i +
      baseball_iq.to_i
  end

  def offensive_score
    hitting_contact.to_i * 2 +
      hitting_power.to_i +
      speed.to_i
  end

  def reliability_score
    coachability.to_i +
      parent_reliability.to_i
  end

  def self.position_scarcity
    Position.all.each_with_object({}) do |position, hash|
      count = position.players.where(team_id: nil).distinct.count
      hash[position.name] = count
    end.sort_by { |_, count| count }.to_h
  end

  def self.positional_dropoff(position_name)
    available = Player.where(team_id: nil)
                      .select { |p| p.plays_position?(position_name) }
                      .sort_by { |p| -p.overall_score.to_f }

    return 0 if available.size < 2

    top = available[0].overall_score.to_f
    second = available[1].overall_score.to_f

    top - second
  end

  def self.top_player_for(position_name)
    Player.where(team_id: nil)
          .joins(:positions)
          .where(positions: { name: position_name })
          .distinct
          .max_by { |p| p.overall_score.to_f }
  end
end
