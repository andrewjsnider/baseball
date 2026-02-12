require "test_helper"

class LineupsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get lineups_show_url
    assert_response :success
  end
end
