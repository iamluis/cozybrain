require "test_helper"

class ReceiptTest < ActiveSupport::TestCase
  test "fixture is valid and has a filing" do
    r = receipts(:lab900_dinner)
    assert r.valid?
    assert_kind_of Filing, r.filing
    assert_equal "expenses", r.filing.folder
  end

  test "amount_cents must be positive" do
    r = receipts(:lab900_dinner).dup
    r.amount_cents = 0
    assert_not r.valid?
  end

  test "currency must be 3 chars" do
    r = receipts(:lab900_dinner).dup
    r.currency = "EU"
    assert_not r.valid?
  end

  test "destroying receipt destroys its filing" do
    r = receipts(:parking_meter)
    filing_id = r.filing.id
    assert_difference -> { Filing.count }, -1 do
      r.destroy
    end
    assert_nil Filing.find_by(id: filing_id)
  end
end
