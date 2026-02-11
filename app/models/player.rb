class Player < ApplicationRecord
  TIERS = %w[Tier1 Tier2 Tier3 Tier4].freeze

  before_save :assign_tier

  belongs_to :team, optional: true
  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  validates :name, presence: true

  def recommendation_score(team)
    score = overall_score

    # Boost pitching if team lacks pitchers
    if team.pitchers_count < 3
      score += pitcher_score * 1.5
    end

    # Boost catcher if none yet
    if team.catchers_count == 0 && primary_position == "C"
      score += 15
    end

    # Boost scarcity
    scarcity = Player.position_scarcity[primary_position] || 0
    if scarcity < 5
      score += 10
    end

    score += flexibility_bonus

    score
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
    scores = Player.pluck(:id).reject { |id| id == self.id }
    return if scores.empty?

    all_players = Player.where.not(id: self.id).to_a + [self]
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
