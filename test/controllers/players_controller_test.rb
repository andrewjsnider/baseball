require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @player = FactoryBot.create(
      :player,
      name: "Draft Kid",
      age: 12,
      primary_position: "P",
      arm_strength: 4,
      pitching_control: 4,
      pitching_velocity: 3,
      speed: 3,
      fielding: 3,
      hitting_contact: 3,
      hitting_power: 2,
      baseball_iq: 4,
      coachability: 4,
      parent_reliability: 5
    )
  end

  def valid_player_params
    {
      name: "New Player",
      age: 11,
      primary_position: "SS",
      arm_strength: 3,
      pitching_control: 3,
      pitching_velocity: 2,
      speed: 4,
      fielding: 4,
      hitting_contact: 3,
      hitting_power: 2,
      baseball_iq: 3,
      coachability: 4,
      parent_reliability: 4
    }
  end

  def test_get_index
    get players_url
    assert_response :success
    assert_select "h1", "Players"
  end

  def test_get_new
    get new_player_url
    assert_response :success
  end

  def test_create_player_with_valid_params
    assert_difference -> { Player.count }, 1 do
      post players_url, params: { player: valid_player_params }
    end

    assert_redirected_to player_url(Player.last)
  end

  def test_create_player_with_invalid_params
    assert_no_difference -> { Player.count } do
      post players_url, params: { player: { name: nil } }
    end

    assert_response :unprocessable_entity
  end

  def test_show_player
    get player_url(@player)
    assert_response :success
    assert_match(/#{Regexp.escape(@player.name)}/, response.body)
  end

  def test_get_edit
    get edit_player_url(@player)
    assert_response :success
  end

  def test_update_player_with_valid_params
    patch player_url(@player), params: {
      player: { name: "Updated Name" }
    }

    assert_redirected_to player_url(@player)
    @player.reload
    assert_equal "Updated Name", @player.name
  end

  def test_update_player_with_invalid_params
    patch player_url(@player), params: {
      player: { name: nil }
    }

    assert_response :unprocessable_entity
  end

  def test_destroy_player
    assert_difference -> { Player.count }, -1 do
      delete player_url(@player)
    end

    assert_redirected_to players_url
  end
end
