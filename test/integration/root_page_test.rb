require "test_helper"

class RootPageTest < ActionDispatch::IntegrationTest
  test "root page renders without authentication" do
    get root_url
    assert_response :success
  end

  test "root page shows brand and tagline" do
    get root_url
    assert_select "h1.brand", text: "brain"
    assert_select "p.landing__tagline"
  end

  test "root page links to sign in" do
    get root_url
    assert_select "a[href=?]", new_session_path, text: "Sign in"
  end
end
