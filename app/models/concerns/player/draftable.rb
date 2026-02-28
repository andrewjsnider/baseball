module Player::Draftable
  extend ActiveSupport::Concern

  def recommendation_score(team, dropoffs: {}, depths: {}, top_by_position: {}, total_teams: Team.count)
    score = overall_score.to_f

    score += confidence_adjustment
    score += stale_adjustment
    score += club_team_bonus
    score += age_adjustment(team)
    score += expected_availability_bonus(team, depths, total_teams)
    score += positional_cliff_bonus(dropoffs, top_by_position)
    score += pitching_bonus(team)
    score += catcher_bonus(team)
    score += short_stop_bonus(team)
    score += up_the_middle_combo_bonus(team)
    score += risk_adjustment(team)
    score += flexibility_bonus(team)
    score += manual_adjustment.to_i

    score.round(1)
  end

  def age_adjustment(team)
    return 0 unless effective_age == 12
    team.spots_remaining > 6 ? 4 : 2
  end

  def expected_availability_bonus(team, depths, total_teams)
    bonus = 0
    positions.each do |position|
      depth = depths[position.name] || 0
      bonus += 8 if depth <= team.picks_until_next_turn(total_teams)
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

  def short_stop_bonus(team)
    return 0 unless plays_position?("SS") || plays_position?("2B")
    return 0 if team.short_stops_needed <= 0
    team.short_stops_needed >= 1 ? 16 : 8
  end

  def up_the_middle_combo_bonus(team)
    return 0 if team.spots_remaining <= 3
    return 0 unless pitch_candidate?
    return 0 unless plays_position?("SS")

    p = uses_ratings_card? ? effective_pitching_rating.to_f : 3.0
    i = uses_ratings_card? ? effective_infield_defense_rating.to_f : 3.0

    ((p + i) / 2.0).round(1)
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
end