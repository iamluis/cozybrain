require "test_helper"

class RootPageTest < ActionDispatch::IntegrationTest
  test "root page renders without authentication" do
    get root_url
    assert_response :success
    assert_match "It works.", response.body
  end
end
