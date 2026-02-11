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
end
