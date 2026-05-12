require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:luis); sign_in_as(@user) }

  test "index shows draft prominently and historical below" do
    get invoices_path
    assert_response :success
    assert_select "a.invoice-card--draft"
    assert_select ".invoice-history__list"
  end

  test "create produces a new draft for the next period" do
    IssuedInvoice.where(invoice_status: "draft").destroy_all

    assert_difference -> { IssuedInvoice.count } => 1, -> { Filing.count } => 1 do
      post invoices_path
    end

    draft = IssuedInvoice.order(:id).last
    assert_equal "draft", draft.invoice_status
    assert_redirected_to invoice_path(draft)
  end

  test "show renders editable form for a draft" do
    draft = issued_invoices(:lab900_may_draft)
    get invoice_path(draft)

    assert_response :success
    assert_select "form[action=?]", invoice_path(draft)
    assert_select "input.invoice__input--desc"
    assert_select "input.invoice__input--qty"
    assert_select "form[action=?]", send_to_client_invoice_path(draft) do
      assert_select "button", text: /Send to Lab900/
    end
  end

  test "show renders read-only view for a sent invoice" do
    sent = issued_invoices(:lab900_april)
    get invoice_path(sent)

    assert_response :success
    assert_select ".invoice__lines--readonly"
    assert_select "input.invoice__input--qty", false
  end

  test "update saves line item edits and recomputes total" do
    draft = issued_invoices(:lab900_may_draft)
    line  = issued_invoice_line_items(:may_consulting_draft)

    patch invoice_path(draft), params: {
      issued_invoice: {
        line_items_attributes: {
          "0" => { id: line.id, position: line.position, description: line.description, quantity: "200", unit_amount_cents: line.unit_amount_cents }
        }
      }
    }

    assert_redirected_to invoice_path(draft)
    assert_equal 200, line.reload.quantity
    assert_equal 1_000_000, draft.reload.amount_cents
  end

  test "update rejects sent invoices" do
    sent = issued_invoices(:lab900_april)
    patch invoice_path(sent), params: { issued_invoice: { client_name: "Other" } }
    assert_redirected_to invoice_path(sent)
    assert_equal "Lab900", sent.reload.client_name
  end

  test "send_to_client creates an Operation and transitions to approved" do
    draft = issued_invoices(:lab900_may_draft)

    assert_difference -> { Operation.count } => 1 do
      post send_to_client_invoice_path(draft)
    end

    op = Operation.order(:id).last
    assert_equal "issue_invoice", op.kind
    assert_equal "pending",       op.status
    assert_equal "Adapter::Null::InvoiceIssuer", op.adapter_name
    assert_equal draft.id,        op.input["invoice_id"]
    assert_equal "approved",      draft.reload.invoice_status
    assert_redirected_to invoice_path(draft)
  end

  test "send_to_client refuses already-sent invoices" do
    sent = issued_invoices(:lab900_april)
    assert_no_difference -> { Operation.count } do
      post send_to_client_invoice_path(sent)
    end
    assert_redirected_to invoice_path(sent)
  end
end
