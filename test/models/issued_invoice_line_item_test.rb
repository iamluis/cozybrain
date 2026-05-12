require "test_helper"

class IssuedInvoiceLineItemTest < ActiveSupport::TestCase
  test "total_cents multiplies quantity by unit amount" do
    li = issued_invoice_line_items(:april_consulting)
    assert_equal 800_000, li.total_cents
  end

  test "position must be unique within invoice" do
    li = issued_invoice_line_items(:april_consulting).dup
    li.description = "Other line"
    assert_not li.valid?
    assert_includes li.errors[:position], "has already been taken"
  end
end
