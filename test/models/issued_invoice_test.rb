require "test_helper"

class IssuedInvoiceTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    IssuedInvoice.all.each { |i| assert i.valid?, i.errors.full_messages.to_s }
  end

  test "number is unique" do
    dup = issued_invoices(:lab900_april).dup
    dup.client_name = "Other"
    assert_not dup.valid?
    assert_includes dup.errors[:number], "has already been taken"
  end

  test "invoice_status predicates" do
    assert issued_invoices(:lab900_april).invoice_sent?
    assert issued_invoices(:lab900_may_draft).invoice_draft?
    assert_not issued_invoices(:lab900_may_draft).invoice_sent?
  end

  test "line items load in position order" do
    invoice = issued_invoices(:lab900_april)
    assert_equal [ 1 ], invoice.line_items.pluck(:position)
  end
end
