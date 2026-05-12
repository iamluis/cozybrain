require "test_helper"

class HomesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:luis)) }

  test "GET /home renders stream and tray" do
    get home_path
    assert_response :success
    assert_select "section.stream"
    assert_select "aside.tray"
  end

  test "stream lists filed filings" do
    get home_path
    assert_select "li.stream__entry .entry__title", text: /Ryanair/
  end

  test "tray surfaces needs_review filing + draft invoice + unmatched txns" do
    get home_path
    assert_select ".tray__item"
    assert_select ".tray__item-title", text: /Modelo 303/
    assert_select ".tray__item-title", text: /Draft invoice/
  end
end
