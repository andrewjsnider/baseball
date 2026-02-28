module Player::Evaluation
  extend ActiveSupport::Concern

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

  def confidence_adjustment
    return 0 unless confidence_level.present?
    -(5 - confidence_level) * 2.0
  end

  def assistant_eval_present?
    assistant_pitching_rating.present? ||
      assistant_hitting_rating.present? ||
      assistant_infield_defense_rating.present? ||
      assistant_outfield_defense_rating.present? ||
      assistant_notes.present?
  end

  def coach_agg_value(v, default: 3.0)
    v.nil? ? default.to_f : v.to_f
  end

  def sources_for_agg(coach:, assistant:, pcr:)
    vals = []
    vals << coach_agg_value(coach)

    if assistant_eval_present?
      vals << (assistant.nil? ? 3.0 : assistant.to_f)
    end

    if pcr.present?
      vals << pcr_component(pcr)
    end

    vals
  end

  def avg(vals)
    return nil if vals.empty?
    (vals.sum / vals.size).round(2)
  end

  def agg_infield
    avg(
      sources_for_agg(
        coach: infield_defense_rating,
        assistant: assistant_infield_defense_rating,
        pcr: pcr_fielding
      )
    )
  end

  def agg_outfield
    avg(
      sources_for_agg(
        coach: outfield_defense_rating,
        assistant: assistant_outfield_defense_rating,
        pcr: pcr_fielding
      )
    )
  end

  def agg_pitch
    avg(
      sources_for_agg(
        coach: pitching_rating,
        assistant: assistant_pitching_rating,
        pcr: pcr_pitching
      )
    )
  end

  def agg_bat
    avg(
      sources_for_agg(
        coach: hitting_rating,
        assistant: assistant_hitting_rating,
        pcr: pcr_hitting
      )
    )
  end

  def effective_value(raw, default: 3.0)
    v = raw.nil? ? default.to_f : raw.to_f
    v * confidence_multiplier
  end

  def effective_pitching_rating = effective_value(pitching_rating)
  def effective_hitting_rating = effective_value(hitting_rating)
  def effective_infield_defense_rating = effective_value(infield_defense_rating)
  def effective_outfield_defense_rating = effective_value(outfield_defense_rating)
  def effective_catching_rating = effective_value(catching_rating)
  def effective_athleticism = effective_value(athleticism)
  def effective_baseball_iq = effective_value(baseball_iq)

  def club_team_bonus
    return 0 unless club_team
    (3.0 * confidence_multiplier).round(1)
  end

  def uses_ratings_card?
    fields = [
      pitching_rating,
      hitting_rating,
      infield_defense_rating,
      outfield_defense_rating,
      catching_rating,
      athleticism,
      baseball_iq,
      speed
    ]

    fields.count(&:present?) >= 4
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
    pitcher_score + defensive_score + offensive_score + reliability_score
  end

  def overall_score
    score =
      if uses_ratings_card?
        ratings_overall_score
      elsif uses_pcr_sheet?
        pcr_overall_score
      else
        legacy_overall_score
      end

    score.round(1)
  end

  def stale_adjustment
    evaluation_stale? ? -(overall_score.to_f * 0.08) : 0
  end

  def evaluation_stale?
    n = notes.to_s.downcase
    return true if n.include?("dnae")
    return true if n.include?("last years scores")
    return true if n.include?("last year's scores")
    return true if n.include?("last years numbers")
    return true if n.include?("last year's numbers")
    false
  end

  def pitcher_score
    pitching_control.to_i * 2 +
      pitching_velocity.to_i +
      arm_strength.to_i +
      baseball_iq.to_i
  end

  def max_pitcher_score = 20.0

  def defensive_score
    fielding.to_i + arm_accuracy.to_i + baseball_iq.to_i
  end

  def offensive_score
    hitting_contact.to_i * 2 + hitting_power.to_i + speed.to_i
  end

  def reliability_score
    coachability.to_i + parent_reliability.to_i
  end

  def uses_pcr_sheet?
    pcr_hitting.present? || pcr_fielding.present? || pcr_throwing.present? ||
      pcr_pitching.present? || pcr_total.present?
  end

  def pcr_component(v)
    n = v.to_f
    return 0.0 if n == 0.0
    n > 5 ? (n / 2.0) : n
  end

  def pcr_overall_score
    return pcr_total.to_f if pcr_total.present?

    pcr_component(pcr_hitting) +
      pcr_component(pcr_fielding) +
      pcr_component(pcr_throwing) +
      pcr_component(pcr_pitching)
  end

  def age_from_pcr_id
    return nil if pcr_id.blank?
    m = pcr_id.match(/\A(?:W)?(\d{2})-/)
    m ? m[1].to_i : nil
  end

  def effective_age
    return age.to_i if age.present?
    age_from_pcr_id
  end
end