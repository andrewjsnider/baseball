class Player < ApplicationRecord
  TIERS = %w[Tier1 Tier2 Tier3 Tier4].freeze

  belongs_to :team, optional: true
  has_many :player_positions, dependent: :destroy
  has_many :positions, through: :player_positions

  validates :name, presence: true

  def recommendation_score(team, dropoffs = {})

    score = overall_score.to_f

    # ----- Confidence (soft linear penalty) -----
    if confidence.present?
      score -= (5 - confidence) * 2.0
    end

    # ----- Stale data (mild reduction) -----
    score *= 0.92 if evaluation_stale?

    # ----- Age (small tiebreaker only) -----
    if team.spots_remaining > 6
      score += 4 if age == 12
    else
      score += 2 if age == 12
    end

    # ----- Weight Expected Next-Round Availability -----
    positions.each do |position|
      depth = Player.where(team_id: nil)
                    .select { |p| p.plays_position?(position.name) }
                    .count

      if depth <= team.picks_until_next_turn(Team.count)
        score += 8
      end
    end

    # ----- Weight positions dropoff -----
    positions.each do |position|
      top_player = Player.top_player_for(position.name)

      if top_player == self
        dropoff = dropoffs[position.name] || 0

        if dropoff > 15
          score += 10
        elsif dropoff > 8
          score += 5
        end
      end
    end

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

      quality_scale = pitcher_score.to_f / max_pitcher_score
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

      score += 3 if scarcity <= 2
    end

    # Adjust for risk
    if risk_flag
      if team.spots_remaining > 6
        score -= 12   # early draft avoid risk
      else
        score -= 4    # late draft risk acceptable
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

  def tier
    players = Player.all.to_a
    return nil if players.size < 5

    sorted = players.sort_by { |p| -p.overall_score }
    index = sorted.index(self)
    percentile = index.to_f / sorted.size

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

  def self.positional_dropoff(position_name)
    available = Player.where(team_id: nil)
                      .select { |p| p.plays_position?(position_name) }
                      .sort_by { |p| -p.overall_score }

    return 0 if available.size < 2

    top = available[0].overall_score
    second = available[1].overall_score

    top - second
  end

  def self.top_player_for(position_name)
    Player.where(team_id: nil)
          .joins(:positions)
          .where(positions: { name: position_name })
          .distinct
          .max_by(&:overall_score)
  end
end
