require "test_helper"

class InSeasonDashboardControllerTest < ActionDispatch::IntegrationTest
  def test_get_in_season_dashboard
    FactoryBot.create(:team, name: 'Giants')
    get root_path
    assert_response :ok
  end
end
