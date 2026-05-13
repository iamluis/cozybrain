require "application_system_test_case"

# Captures a screenshot of the invoice draft surface so Claude can read
# back what the page actually renders. Not a regression test — a visual
# debugging artifact.
class InvoiceDraftSnapshotTest < ApplicationSystemTestCase
  test "snapshot draft invoice" do
    user = users(:luis)

    visit new_session_path
    fill_in "Email",    with: user.email_address
    fill_in "Password", with: "password"
    click_on "Sign in"

    # Wait for the auth redirect to settle on the home page.
    assert_no_current_path "/session/new", wait: 5

    draft = issued_invoices(:lab900_may_draft)
    visit invoice_path(draft)

    assert_text "Invoice", wait: 5
    sleep 0.3   # let Stimulus settle before snapshot
    page.save_screenshot Rails.root.join("tmp/screenshots/invoice_draft.png").to_s

    # Scroll to bottom and capture the settings + send button.
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")
    sleep 0.2
    page.save_screenshot Rails.root.join("tmp/screenshots/invoice_draft_bottom.png").to_s
  end
end
