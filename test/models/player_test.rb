require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  def setup
    @player = FactoryBot.build(
      :player,
      pitching_control: 4,
      pitching_velocity: 3,
      arm_strength: 5,
      baseball_iq: 4,
      fielding: 3,
      arm_accuracy: 4,
      hitting_contact: 4,
      hitting_power: 3,
      speed: 4,
      coachability: 5,
      parent_reliability: 4,

      # Ensure we stay on legacy scoring in these tests
      pitching_rating: nil,
      hitting_rating: nil,
      infield_defense_rating: nil,
      outfield_defense_rating: nil,
      catching_rating: nil,
      athleticism: nil,
      confidence_level: nil
    )
  end

  def test_pitcher_score_calculation
    expected =
      4 * 2 +  # pitching_control weighted
      3 +      # pitching_velocity
      5 +      # arm_strength
      4        # baseball_iq

    assert_equal expected, @player.pitcher_score
  end

  def test_pitcher_score_handles_nil_values
    @player.pitching_control = nil
    @player.pitching_velocity = nil
    @player.arm_strength = nil
    @player.baseball_iq = nil

    assert_equal 0, @player.pitcher_score
  end

  def test_defensive_score_calculation
    expected =
      3 +  # fielding
      4 +  # arm_accuracy
      4    # baseball_iq

    assert_equal expected, @player.defensive_score
  end

  def test_defensive_score_handles_nil_values
    @player.fielding = nil
    @player.arm_accuracy = nil
    @player.baseball_iq = nil

    assert_equal 0, @player.defensive_score
  end

  def test_offensive_score_calculation
    expected =
      4 * 2 +  # hitting_contact weighted
      3 +      # hitting_power
      4        # speed

    assert_equal expected, @player.offensive_score
  end

  def test_offensive_score_handles_nil_values
    @player.hitting_contact = nil
    @player.hitting_power = nil
    @player.speed = nil

    assert_equal 0, @player.offensive_score
  end

  def test_reliability_score_calculation
    expected =
      5 +  # coachability
      4    # parent_reliability

    assert_equal expected, @player.reliability_score
  end

  def test_reliability_score_handles_nil_values
    @player.coachability = nil
    @player.parent_reliability = nil

    assert_equal 0, @player.reliability_score
  end

  def test_legacy_overall_score_combines_all_scores
    expected =
      @player.pitcher_score +
      @player.defensive_score +
      @player.offensive_score +
      @player.reliability_score

    assert_equal expected, @player.legacy_overall_score
  end

  def test_legacy_overall_score_is_zero_when_all_metrics_nil
    @player.assign_attributes(
      pitching_control: nil,
      pitching_velocity: nil,
      arm_strength: nil,
      baseball_iq: nil,
      fielding: nil,
      arm_accuracy: nil,
      hitting_contact: nil,
      hitting_power: nil,
      speed: nil,
      coachability: nil,
      parent_reliability: nil
    )

    assert_equal 0, @player.legacy_overall_score
  end

  def test_overall_score_uses_ratings_card_when_present
    @player.assign_attributes(
      pitching_rating: 5,
      hitting_rating: 5,
      infield_defense_rating: 5,
      outfield_defense_rating: 5,
      catching_rating: 5,
      athleticism: 5,
      confidence_level: 5
    )

    assert @player.uses_ratings_card?
    assert @player.overall_score > 0
    assert_equal @player.ratings_overall_score.round(1), @player.overall_score
  end

  def test_computed_tier_assigns_a_for_top_player
    Player.destroy_all

    10.times do
      FactoryBot.create(
        :player,
        pitching_rating: 1,
        hitting_rating: 1,
        infield_defense_rating: 1,
        outfield_defense_rating: 1,
        catching_rating: 1,
        baseball_iq: 1,
        athleticism: 1,
        confidence_level: 5
      )
    end

    elite = FactoryBot.create(
      :player,
      pitching_rating: 5,
      hitting_rating: 5,
      infield_defense_rating: 5,
      outfield_defense_rating: 5,
      catching_rating: 5,
      baseball_iq: 5,
      athleticism: 5,
      confidence_level: 5
    )

    assert_equal "A", elite.computed_tier
  end

  def test_position_scarcity_orders_lowest_first
    Player.destroy_all
    Position.destroy_all

    c = Position.create!(name: "C")
    p = Position.create!(name: "P")

    2.times do
      player = FactoryBot.create(:player)
      player.positions << c
    end

    5.times do
      player = FactoryBot.create(:player)
      player.positions << p
    end

    scarcity = Player.position_scarcity
    first_key = scarcity.keys.first
    assert_equal "C", first_key
  end

  def test_computed_tier_assigns_correct_percentile_groups
    Player.destroy_all

    20.times do |i|
      FactoryBot.create(
        :player,
        pitching_rating: (i % 5) + 1,
        hitting_rating: (i % 5) + 1,
        infield_defense_rating: (i % 5) + 1,
        outfield_defense_rating: (i % 5) + 1,
        catching_rating: (i % 5) + 1,
        baseball_iq: (i % 5) + 1,
        athleticism: (i % 5) + 1,
        speed: (i % 5) + 1,
        confidence_level: 5,
        manual_adjustment: i # force strict ordering so percentiles are stable
      )
    end

    players = Player.all.sort_by { |p| -p.overall_score.to_f }

    # computed_tier uses 15% / 35% cutoffs
    assert_equal "A", players[0].computed_tier
    assert_equal "A", players[2].computed_tier

    assert_equal "B", players[4].computed_tier

    assert_equal "C", players[10].computed_tier
    assert_equal "C", players.last.computed_tier
  end

  def test_computed_tier_handles_small_dataset
    Player.destroy_all

    3.times { FactoryBot.create(:player) }

    Player.all.each do |player|
      assert_nil player.computed_tier
    end
  end
end
