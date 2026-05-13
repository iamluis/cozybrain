require "application_system_test_case"

class HomeAfter0014SnapshotTest < ApplicationSystemTestCase
  test "snapshot home after proof-ledger" do
    user = users(:luis)
    visit new_session_path
    fill_in "Email",    with: user.email_address
    fill_in "Password", with: "password"
    click_on "Sign in"
    assert_no_current_path "/session/new", wait: 5

    visit home_path
    assert_text(/tray/i, wait: 5)
    sleep 0.3
    page.save_screenshot Rails.root.join("tmp/screenshots/home_0014.png").to_s

    # And the match-candidates page.
    txn = bank_transactions(:parking_charge)
    visit new_ledger_match_path(bank_transaction_id: txn.id)
    assert_text "Match a receipt", wait: 5
    sleep 0.3
    page.save_screenshot Rails.root.join("tmp/screenshots/home_0014_match.png").to_s
  end
end
