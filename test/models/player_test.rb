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
      parent_reliability: 4
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

  def test_overall_score_combines_all_scores
    expected =
      @player.pitcher_score +
      @player.defensive_score +
      @player.offensive_score +
      @player.reliability_score

    assert_equal expected, @player.overall_score
  end

  def test_overall_score_is_zero_when_all_metrics_nil
    @player.attributes.each do |key, value|
      if @player.respond_to?(key) && value.is_a?(Integer)
        @player.send("#{key}=", nil)
      end
    end

    assert_equal 0, @player.overall_score
  end

  def test_assigns_tier1_for_top_player
    FactoryBot.create_list(:player, 10, arm_strength: 1)

    elite = FactoryBot.create(
      :player,
      pitching_control: 5,
      pitching_velocity: 5,
      arm_strength: 5,
      baseball_iq: 5,
      hitting_contact: 5,
      hitting_power: 5,
      speed: 5,
      fielding: 5,
      coachability: 5,
      parent_reliability: 5
    )

    assert_equal "Tier1", elite.tier
  end

  def test_position_scarcity_orders_lowest_first
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

  def test_assigns_tier1_for_top_player
    Player.destroy_all

    FactoryBot.create_list(:player, 10,
      pitching_control: 1,
      pitching_velocity: 1,
      arm_strength: 1,
      baseball_iq: 1,
      hitting_contact: 1,
      hitting_power: 1,
      speed: 1,
      fielding: 1,
      coachability: 1,
      parent_reliability: 1
    )

    elite = FactoryBot.create(
      :player,
      pitching_control: 5,
      pitching_velocity: 5,
      arm_strength: 5,
      baseball_iq: 5,
      hitting_contact: 5,
      hitting_power: 5,
      speed: 5,
      fielding: 5,
      coachability: 5,
      parent_reliability: 5
    )

    assert_equal "Tier1", elite.tier
  end

  def test_overall_score_is_zero_when_all_metrics_nil
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

    assert_equal 0, @player.overall_score
  end

  def test_tier_assigns_correct_percentile_groups
    Player.destroy_all

    # Create 20 players with ascending strength
    20.times do |i|
      FactoryBot.create(
        :player,
        pitching_control: i,
        pitching_velocity: i,
        arm_strength: i,
        baseball_iq: i,
        fielding: i,
        arm_accuracy: i,
        hitting_contact: i,
        hitting_power: i,
        speed: i,
        coachability: i,
        parent_reliability: i
      )
    end

    players = Player.all.sort_by { |p| -p.overall_score }

    # Top 15% → Tier1 (3 players out of 20)
    assert_equal "Tier1", players[0].tier
    assert_equal "Tier1", players[2].tier

    # Around 20–35% → Tier2
    assert_equal "Tier2", players[4].tier

    # Middle → Tier3
    assert_equal "Tier3", players[10].tier

    # Bottom → Tier4
    assert_equal "Tier4", players.last.tier
  end

  def test_tier_handles_small_dataset
    Player.destroy_all

    3.times do
      FactoryBot.create(:player)
    end

    Player.all.each do |player|
      assert_nil player.tier
    end
  end
end
