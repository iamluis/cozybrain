require "application_system_test_case"

# Phone-width snapshots so Claude can audit the mobile experience.
class MobileSnapshotsTest < ApplicationSystemTestCase
  setup do
    # Resize the window per-test — driven_by in a subclass doesn't reliably
    # override the Capybara session that's already set up.
    page.driver.browser.manage.window.resize_to(390, 1300)
  end

  def sign_in
    user = users(:luis)
    visit new_session_path
    fill_in "Email",    with: user.email_address
    fill_in "Password", with: "password"
    click_on "Sign in"
    assert_no_current_path "/session/new", wait: 5
  end

  test "snapshot home on mobile" do
    sign_in
    visit home_path
    assert_text(/tray/i, wait: 5)
    sleep 0.4
    page.save_screenshot Rails.root.join("tmp/screenshots/mobile_home.png").to_s
  end

  test "snapshot invoice draft on mobile" do
    sign_in
    visit invoice_path(issued_invoices(:lab900_may_draft))
    assert_text "Invoice", wait: 5
    sleep 0.4
    page.save_screenshot Rails.root.join("tmp/screenshots/mobile_invoice.png").to_s
  end

  test "snapshot capture form on mobile" do
    sign_in
    visit new_receipt_path
    assert_selector "form[enctype='multipart/form-data']", wait: 5
    sleep 0.4
    page.save_screenshot Rails.root.join("tmp/screenshots/mobile_capture.png").to_s
  end

  test "snapshot invoices index on mobile" do
    sign_in
    visit invoices_path
    assert_text "Invoices", wait: 5
    sleep 0.4
    page.save_screenshot Rails.root.join("tmp/screenshots/mobile_invoices.png").to_s
  end
end
