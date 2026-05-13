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
    assert_select "button.invoice__add-line", text: /Add a line/
    assert_select "button.invoice__remove"
    assert_select "[data-controller='invoice-lines']"
    assert_select "form[action=?]", send_to_client_invoice_path(draft) do
      assert_select "button", text: /Send to Lab900/
    end
  end

  test "update can add a new line item via nested attributes" do
    draft = issued_invoices(:lab900_may_draft)
    existing_line = issued_invoice_line_items(:may_consulting_draft)

    assert_difference -> { draft.line_items.reload.count } => 1 do
      patch invoice_path(draft), params: {
        issued_invoice: {
          line_items_attributes: {
            "0" => { id: existing_line.id, position: existing_line.position, description: existing_line.description, quantity: existing_line.quantity.to_s, unit_amount_cents: existing_line.unit_amount_cents, _destroy: "0" },
            "1718000000000" => { id: "", position: "2", description: "Extra travel", quantity: "1.0", unit_amount_cents: "12000", _destroy: "0" }
          }
        }
      }
    end

    assert_redirected_to invoice_path(draft)
  end

  test "update can remove a line item via _destroy" do
    draft = issued_invoices(:lab900_may_draft)
    line  = issued_invoice_line_items(:may_consulting_draft)

    assert_difference -> { draft.line_items.reload.count } => -1 do
      patch invoice_path(draft), params: {
        issued_invoice: {
          line_items_attributes: {
            "0" => { id: line.id, position: line.position, description: line.description, quantity: line.quantity.to_s, unit_amount_cents: line.unit_amount_cents, _destroy: "1" }
          }
        }
      }
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

  test "update can change service period and filing's period syncs" do
    draft = issued_invoices(:lab900_may_draft)

    patch invoice_path(draft), params: {
      issued_invoice: {
        service_period_start: "2026-06-01",
        service_period_end:   "2026-06-30"
      }
    }

    draft.reload
    assert_equal Date.new(2026, 6, 30), draft.service_period_end
    assert_equal 6,                     draft.period_month
    assert_equal 6,                     draft.filing.reload.period_month
    assert_redirected_to invoice_path(draft)
  end

  test "update can switch the per-invoice tax_treatment override" do
    draft = issued_invoices(:lab900_may_draft)
    patch invoice_path(draft), params: { issued_invoice: { tax_treatment: "domestic_vat_21" } }
    assert_equal "domestic_vat_21", draft.reload.tax_treatment
    assert draft.tax_amount_cents.positive?
  end

  test "show renders client picker + service period inputs + tax treatment select" do
    draft = issued_invoices(:lab900_may_draft)
    get invoice_path(draft)

    assert_select "select[name='issued_invoice[client_id]']"
    assert_select "input[name='issued_invoice[service_period_start]']"
    assert_select "input[name='issued_invoice[service_period_end]']"
    assert_select "select[name='issued_invoice[tax_treatment]']"
    assert_select "input[name='issued_invoice[payment_terms_days]']"
    assert_select "input[name='issued_invoice[iban_override]']"
    assert_select "textarea[name='issued_invoice[notes]']"
  end
end
