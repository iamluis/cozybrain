require "application_system_test_case"

class PulseSnapshotTest < ApplicationSystemTestCase
  test "snapshot pulse page" do
    user = users(:luis)
    visit new_session_path
    fill_in "Email",    with: user.email_address
    fill_in "Password", with: "password"
    click_on "Sign in"
    assert_no_current_path "/session/new", wait: 5

    visit pulse_path
    assert_text "Weekly pulse", wait: 5
    sleep 0.3
    page.save_screenshot Rails.root.join("tmp/screenshots/pulse.png").to_s
  end
end
