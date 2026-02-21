require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  def test_index
    FactoryBot.create(:team, name: 'Giants')
    get root_path
    assert_response :success
  end
end
