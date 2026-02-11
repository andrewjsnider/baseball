class Player < ApplicationRecord
  TIERS = %w[Tier1 Tier2 Tier3 Tier4].freeze

  before_save :assign_tier

  belongs_to :team, optional: true
  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  validates :name, presence: true

  def recommendation_score(team)
    score = overall_score.to_f

    # ----- Confidence (soft linear penalty) -----
    if confidence.present?
      score -= (5 - confidence) * 2.0
    end

    # ----- Stale data (mild reduction) -----
    score *= 0.92 if evaluation_stale?

    # ----- Age (small tiebreaker only) -----
    score += 4 if age == 12

    # ----- Pitching Marginal Value -----
    if plays_position?("P")
      need_bonus = 0

      if team.pitchers_count == 0
        need_bonus = 28
      elsif team.pitchers_count == 1
        need_bonus = 20
      elsif team.pitchers_count == 2
        need_bonus = 10
      end

      quality_scale = pitcher_score / 20.0
      score += need_bonus * quality_scale
    end

    # ----- Catcher Marginal Value -----
    if plays_position?("C")
      if team.catchers_count == 0
        score += 18
      elsif team.catchers_count == 1
        score += 6
      end
    end

    # ----- Scarcity (supportive only) -----
    scarcity_hash = Player.position_scarcity

    positions.each do |position|
      scarcity = scarcity_hash[position.name] || 0

      if scarcity <= 2
        score += 6
      elsif scarcity <= 4
        score += 3
      end
    end

    # ----- Flexibility (phase-aware) -----
    flex = positions.count

    if team.spots_remaining <= 3
      score += flex * 4
    else
      score += flex * 2
    end

    score
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

  def overall_score
    pitcher_score +
    defensive_score +
    offensive_score +
    reliability_score
  end

  def flexibility_bonus
    positions.count > 1 ? 5 : 0
  end

  def self.position_scarcity
    Position.all.each_with_object({}) do |position, hash|
      count = position.players.where(team_id: nil).distinct.count
      hash[position.name] = count
    end.sort_by { |_, count| count }.to_h
  end

  def assign_tier
    all_players = Player.where.not(id: id).to_a + [self]
    return if all_players.size < 5

    sorted = all_players.sort_by(&:overall_score).reverse
    index = sorted.index(self)
    percentile = index.to_f / sorted.size

    self.tier =
      if percentile <= 0.15
        "Tier1"
      elsif percentile <= 0.35
        "Tier2"
      elsif percentile <= 0.65
        "Tier3"
      else
        "Tier4"
      end
  end
end
