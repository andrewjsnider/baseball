require "test_helper"

class LineupsControllerTest < ActionDispatch::IntegrationTest
  def test_get_show
    team = FactoryBot.create(:team)
    game = FactoryBot.create(:game, team: team, opponent: team)
    lineup = FactoryBot.create(:lineup, game: game)
    get game_lineup_path(game)
    assert_response :success
  end
end
