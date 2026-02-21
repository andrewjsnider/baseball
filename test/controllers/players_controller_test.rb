require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @pitcher = FactoryBot.create(:position, name: "P")
    @shortstop = FactoryBot.create(:position, name: "SS")

    @team = FactoryBot.create(:team, name: "Giants")
    @other_team = FactoryBot.create(:team, name: "Team B")

    @player = FactoryBot.create(
      :player,
      name: "Draft Kid",
      age: 12,
      pitching_rating: 4,
      hitting_rating: 3,
      infield_defense_rating: 3,
      outfield_defense_rating: 2,
      catching_rating: 2,
      baseball_iq: 4,
      athleticism: 4,
      speed: 3,
      confidence_level: 4,
      can_pitch: true,
      can_catch: false,
      notes: "Strong arm",
      risk_flag: false,
      team: nil
    )

    @player.positions << @pitcher
  end

  def valid_player_params
    {
      name: "New Player",
      age: 11,
      tier: "B",
      confidence_level: 3,
      manual_adjustment: 0,
      notes: "Good athlete",
      risk_flag: false,
      evaluation_date: Date.today,

      pitching_rating: 3,
      hitting_rating: 3,
      infield_defense_rating: 4,
      outfield_defense_rating: 3,
      catching_rating: 2,
      baseball_iq: 3,
      athleticism: 4,
      speed: 4,

      can_pitch: false,
      can_catch: false,

      position_ids: [@shortstop.id]
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
    assert_equal "New Player", Player.last.name
    assert_equal ["SS"], Player.last.positions.pluck(:name)
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
      player: { name: "Updated Name", confidence_level: 5 }
    }

    assert_redirected_to player_url(@player)
    @player.reload
    assert_equal "Updated Name", @player.name
    assert_equal 5, @player.confidence_level
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

  def test_get_assign
    get assign_player_url(@player)
    assert_response :success
    assert_select "h1", /Assign/
  end

  def test_assigns_player_to_team
    patch assign_to_team_player_url(@player), params: { team_id: @team.id }

    assert_redirected_to root_path
    @player.reload
    assert_equal @team.id, @player.team_id
  end

  def test_reassigns_player_to_different_team
    @player.update!(team: @team)

    patch assign_to_team_player_url(@player), params: { team_id: @other_team.id }

    @player.reload
    assert_equal @other_team.id, @player.team_id
  end
end
