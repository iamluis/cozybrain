require "application_system_test_case"

class ReceiptPhotoSnapshotTest < ApplicationSystemTestCase
  test "snapshot receipt show with photo" do
    user    = users(:luis)
    receipt = receipts(:lab900_dinner)
    receipt.original_photo.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample_receipt.png")),
      filename:     "receipt.png",
      content_type: "image/png"
    )

    visit new_session_path
    fill_in "Email",    with: user.email_address
    fill_in "Password", with: "password"
    click_on "Sign in"
    assert_no_current_path "/session/new", wait: 5

    visit receipt_path(receipt)
    assert_text "Saved", wait: 5
    sleep 0.5
    page.save_screenshot Rails.root.join("tmp/screenshots/receipt_with_photo.png").to_s
  end
end
