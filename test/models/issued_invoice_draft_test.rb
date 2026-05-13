require "test_helper"

class IssuedInvoiceDraftTest < ActiveSupport::TestCase
  test "next_number_for produces zero-padded sequence per year" do
    assert_equal "2026-0006", IssuedInvoice.next_number_for(year: 2026)
    assert_equal "2027-0001", IssuedInvoice.next_number_for(year: 2027)
  end

  test "draft_next clones structure from last invoice for the given client" do
    user   = users(:luis)
    client = clients(:lab900)
    draft  = IssuedInvoice.draft_next(user: user, client: client, period_year: 2026, period_month: 6)
    assert draft.save, draft.errors.full_messages.to_s

    assert_equal "2026-0006",                  draft.number
    assert_equal client,                       draft.client
    assert_equal "draft",                      draft.invoice_status
    assert_equal "EUR",                        draft.currency
    assert_equal Date.new(2026, 6, 1),         draft.service_period_start
    assert_equal Date.new(2026, 6, 30),        draft.service_period_end
    assert_equal 2026,                         draft.period_year
    assert_equal 6,                            draft.period_month
    assert_equal 1,                            draft.line_items.size
    assert_match(/June 2026/,                  draft.line_items.first.description)
  end

  test "subtotal_cents sums line items" do
    invoice = issued_invoices(:lab900_april)
    assert_equal 800_000, invoice.subtotal_cents
  end

  test "total_cents adds tax for domestic_vat_21" do
    invoice = issued_invoices(:lab900_april)
    invoice.update!(tax_treatment: "domestic_vat_21")
    assert_equal 800_000,            invoice.subtotal_cents
    assert_equal (800_000 * 0.21).to_i, invoice.tax_amount_cents
    assert_equal 968_000,            invoice.total_cents
  end

  test "total_cents == subtotal for intra_eu_reverse_charge" do
    invoice = issued_invoices(:lab900_april)
    assert_equal "intra_eu_reverse_charge", invoice.effective_tax_treatment
    assert_equal invoice.subtotal_cents, invoice.total_cents
  end

  test "recompute_total! syncs amount_cents to total_cents" do
    invoice = issued_invoices(:lab900_april)
    invoice.line_items.first.update!(quantity: 100)
    invoice.recompute_total!
    assert_equal 500_000, invoice.reload.amount_cents
  end

  test "period_label uses service_period_end month" do
    assert_equal "April 2026", issued_invoices(:lab900_april).period_label
  end

  test "effective_tax_treatment falls back to client default" do
    invoice = issued_invoices(:lab900_may_draft)
    invoice.update!(tax_treatment: nil)
    assert_equal "intra_eu_reverse_charge", invoice.effective_tax_treatment
  end

  test "service_period_end before start is rejected" do
    invoice = issued_invoices(:lab900_may_draft)
    invoice.service_period_start = Date.new(2026, 5, 31)
    invoice.service_period_end   = Date.new(2026, 5, 1)
    refute invoice.valid?
    assert_includes invoice.errors[:service_period_end], "must be on or after the start date"
  end
end
