require "test_helper"

class IssuedInvoiceDraftTest < ActiveSupport::TestCase
  test "next_number_for produces zero-padded sequence per year" do
    assert_equal "2026-0006", IssuedInvoice.next_number_for(year: 2026)
    assert_equal "2027-0001", IssuedInvoice.next_number_for(year: 2027)
  end

  test "draft_next clones structure from last invoice and assigns next number" do
    user  = users(:luis)
    draft = IssuedInvoice.draft_next(user: user, period_year: 2026, period_month: 6)
    assert draft.save, draft.errors.full_messages.to_s

    assert_equal "2026-0006",  draft.number
    assert_equal "Lab900",     draft.client_name
    assert_equal "draft",      draft.invoice_status
    assert_equal "EUR",        draft.currency
    assert_equal 2026,         draft.period_year
    assert_equal 6,            draft.period_month
    assert_equal 1,            draft.line_items.size
    assert_match(/June 2026/,  draft.line_items.first.description)
  end

  test "computed_total_cents sums line items" do
    invoice = issued_invoices(:lab900_april)
    assert_equal 800_000, invoice.computed_total_cents
  end

  test "recompute_total! syncs amount_cents" do
    invoice = issued_invoices(:lab900_april)
    invoice.line_items.first.update!(quantity: 100)
    invoice.recompute_total!
    assert_equal 500_000, invoice.reload.amount_cents
  end

  test "period_label renders human month" do
    assert_equal "April 2026", issued_invoices(:lab900_april).period_label
  end
end
