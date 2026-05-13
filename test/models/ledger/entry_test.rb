require "test_helper"

class Ledger::EntryTest < ActiveSupport::TestCase
  test "proven when both sides agree on amount and date" do
    entry = Ledger::Entry.new(
      filing:           filings(:lab900_dinner_filing),
      bank_transaction: bank_transactions(:dinner_charge)
    )
    assert_equal :proven,  entry.state
    assert entry.proven?
  end

  test "proven when filed proof is present (bank match not required)" do
    entry = Ledger::Entry.new(filing: filings(:ryanair_filing), bank_transaction: nil)
    assert_equal :proven, entry.state
    assert_nil entry.open_reason
  end

  test "open when only money side is present" do
    entry = Ledger::Entry.new(filing: nil, bank_transaction: bank_transactions(:parking_charge))
    assert_equal :open, entry.state
    assert_equal :needs_proof, entry.open_reason
  end

  test "open when draft invoice needs sending" do
    entry = Ledger::Entry.new(
      filing:           filings(:lab900_may_draft_filing),
      bank_transaction: nil
    )
    assert_equal :open, entry.state
    assert_equal :needs_send, entry.open_reason
  end

  test "open when filing needs review (low confidence inbound doc)" do
    entry = Ledger::Entry.new(filing: filings(:modelo_303_filing), bank_transaction: nil)
    assert_equal :open, entry.state
    assert_equal :needs_review, entry.open_reason
  end

  test "dismissed when filing trashed" do
    filing = filings(:ryanair_filing)
    filing.update!(trashed_at: Time.current)
    entry = Ledger::Entry.new(filing: filing, bank_transaction: nil)
    assert_equal :dismissed, entry.state
  end

  test "dismissed when bank transaction dismissed" do
    txn = bank_transactions(:parking_charge)
    txn.dismiss!
    entry = Ledger::Entry.new(filing: nil, bank_transaction: txn)
    assert_equal :dismissed, entry.state
  end

  test "kind: income for IssuedInvoice proof" do
    entry = Ledger::Entry.new(filing: filings(:lab900_april_filing), bank_transaction: nil)
    assert_equal :income, entry.kind
  end

  test "kind: expense for Receipt proof" do
    entry = Ledger::Entry.new(filing: filings(:lab900_dinner_filing), bank_transaction: nil)
    assert_equal :expense, entry.kind
  end

  test "kind: tax for tax_doc ReceivedDocument" do
    entry = Ledger::Entry.new(filing: filings(:modelo_303_filing), bank_transaction: nil)
    assert_equal :tax, entry.kind
  end

  test "amount: signed expense for Receipt" do
    entry = Ledger::Entry.new(filing: filings(:lab900_dinner_filing), bank_transaction: nil)
    assert entry.amount.negative?, "Expected receipt amount to be negative, got #{entry.amount}"
  end

  test "amount: positive income for IssuedInvoice" do
    entry = Ledger::Entry.new(filing: filings(:lab900_april_filing), bank_transaction: nil)
    assert entry.amount.positive?
  end

  test "open when amounts mismatch even if both sides present" do
    filing = filings(:ryanair_filing)  # ReceivedDocument — no amount_cents
    txn    = bank_transactions(:parking_charge)
    entry = Ledger::Entry.new(filing: filing, bank_transaction: txn)
    # ReceivedDocument has no amount, so amounts can't match → open.
    assert_equal :open, entry.state
    assert_equal :amount_mismatch, entry.open_reason
  end

  test "factory from_bank_transaction returns one-sided entry when unmatched" do
    txn = bank_transactions(:parking_charge)
    entry = Ledger::Entry.from_bank_transaction(txn)
    assert_nil entry.proof_side
    assert_equal txn, entry.money_side
  end
end
