require "test_helper"

class ReceiptsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:luis) }

  test "new redirects unauthenticated users to sign in" do
    get new_receipt_path
    assert_redirected_to new_session_path
  end

  test "new renders the capture form when signed in" do
    sign_in_as(@user)
    get new_receipt_path
    assert_response :success
    assert_select "form[enctype='multipart/form-data']"
    assert_select "input[name='receipt[amount]'][type='number']"
    assert_select "input[name='receipt[original_photo]'][type='file'][capture='environment']"
    assert_select "select[name='receipt[country]']"
    assert_select "input[name='receipt[note]']"
  end

  test "create with valid params creates receipt and filing in one transaction" do
    sign_in_as(@user)

    assert_difference -> { Receipt.count } => 1, -> { Filing.count } => 1 do
      post receipts_path, params: {
        receipt: {
          amount: "23.50",
          paid_on: "2026-05-12",
          vendor: "Le Pain Quotidien",
          country: "BE",
          note: "dinner with Matthias"
        }
      }
    end

    receipt = Receipt.order(:id).last
    assert_equal 2350, receipt.amount_cents
    assert_equal "EUR", receipt.currency
    assert_redirected_to receipt_path(receipt)

    filing = receipt.filing
    assert_equal @user,    filing.user
    assert_equal "expenses", filing.folder
    assert_equal "capture",  filing.source
    assert_equal "pending",  filing.status
    assert_equal 2026, filing.period_year
    assert_equal 5,    filing.period_month
    assert_equal "dinner with Matthias", filing.note
    assert filing.received_at.present?
  end

  test "create with invalid params re-renders new" do
    sign_in_as(@user)

    assert_no_difference -> { Receipt.count } do
      post receipts_path, params: { receipt: { amount: "", paid_on: "2026-05-12" } }
    end

    assert_response :unprocessable_content
    assert_select "form[enctype='multipart/form-data']"
  end

  test "show renders the saved confirmation with Add another and Done" do
    sign_in_as(@user)
    receipt = receipts(:lab900_dinner)

    get receipt_path(receipt)
    assert_response :success
    assert_select "a[href=?]", new_receipt_path, text: "Add another"
    assert_select "a[href=?]", root_path,        text: "Done"
  end

  test "show includes an Edit affordance pointing at edit_receipt_path" do
    sign_in_as(@user)
    receipt = receipts(:lab900_dinner)

    get receipt_path(receipt)
    assert_select "a[href=?]", edit_receipt_path(receipt), text: "Edit"
  end

  test "show renders the photo when one is attached" do
    sign_in_as(@user)
    receipt = receipts(:lab900_dinner)
    receipt.original_photo.attach(
      io:           File.open(Rails.root.join("test/fixtures/files/sample_receipt.png")),
      filename:     "receipt.png",
      content_type: "image/png"
    )

    get receipt_path(receipt)
    assert_select "a.card__photo img.card__photo-img"
  end

  test "edit renders the form with current values" do
    sign_in_as(@user)
    receipt = receipts(:lab900_dinner)

    get edit_receipt_path(receipt)
    assert_response :success
    assert_select "form[enctype='multipart/form-data']"
    assert_select "input[name='receipt[vendor]'][value=?]", receipt.vendor
    assert_select "input[name='receipt[note]']"
  end

  test "update with valid params persists changes including filing note" do
    sign_in_as(@user)
    receipt = receipts(:lab900_dinner)

    patch receipt_path(receipt), params: {
      receipt: {
        amount: "30.00",
        paid_on: receipt.paid_on,
        vendor: "Le Pain Quotidien (Sablon)",
        country: "BE",
        note: "updated note"
      }
    }

    receipt.reload
    assert_equal 3000, receipt.amount_cents
    assert_equal "Le Pain Quotidien (Sablon)", receipt.vendor
    assert_equal "updated note", receipt.filing.note
    assert_redirected_to receipt_path(receipt)
  end

  test "update with invalid params re-renders edit" do
    sign_in_as(@user)
    receipt = receipts(:lab900_dinner)

    patch receipt_path(receipt), params: {
      receipt: { amount: receipt.amount, paid_on: "" }
    }

    assert_response :unprocessable_content
    assert_select "form[enctype='multipart/form-data']"
  end
end
