require "test_helper"

class BankTransactionTest < ActiveSupport::TestCase
  test "fixtures are valid" do
    BankTransaction.all.each { |t| assert t.valid?, t.errors.full_messages.to_s }
  end

  test "unmatched scope returns only transactions without a filing" do
    unmatched = BankTransaction.unmatched
    assert_includes unmatched, bank_transactions(:parking_charge)
    assert_includes unmatched, bank_transactions(:mystery_charge)
    assert_not_includes unmatched, bank_transactions(:dinner_charge)
  end

  test "matched? reflects matched_filing presence" do
    assert     bank_transactions(:dinner_charge).matched?
    assert_not bank_transactions(:mystery_charge).matched?
  end

  test "holded_ref is required and unique" do
    t = bank_transactions(:mystery_charge).dup
    t.holded_ref = bank_transactions(:dinner_charge).holded_ref
    assert_not t.valid?
  end
end
