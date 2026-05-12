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
end
