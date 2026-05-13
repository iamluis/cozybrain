require "test_helper"

class LedgerHelperTest < ActionView::TestCase
  include LedgerHelper

  test "proven → 'Filed'" do
    entry = Ledger::Entry.new(filing: filings(:lab900_dinner_filing), bank_transaction: bank_transactions(:dinner_charge))
    assert_equal "Filed", ledger_state_label(entry)
  end

  test "open + needs_proof → 'Match a receipt' + verb 'Match'" do
    entry = Ledger::Entry.from_bank_transaction(bank_transactions(:parking_charge))
    assert_equal "Match a receipt", ledger_state_label(entry)
    assert_equal "Match",            ledger_state_verb(entry)
  end

  test "open + needs_send (draft invoice) → 'Send to client' + verb 'Send'" do
    entry = Ledger::Entry.new(filing: filings(:lab900_may_draft_filing), bank_transaction: nil)
    assert_equal "Send to client", ledger_state_label(entry)
    assert_equal "Send",           ledger_state_verb(entry)
  end

  test "open + needs_review (inbound doc) → 'File this' + verb 'File'" do
    entry = Ledger::Entry.new(filing: filings(:modelo_303_filing), bank_transaction: nil)
    assert_equal "File this", ledger_state_label(entry)
    assert_equal "File",      ledger_state_verb(entry)
  end

  test "filed proof with no bank match is Proven (gestoria doesn't need bank)" do
    entry = Ledger::Entry.new(filing: filings(:ryanair_filing), bank_transaction: nil)
    assert_equal "Filed", ledger_state_label(entry)
    assert_nil ledger_state_verb(entry)
  end

  test "kind labels" do
    expense  = Ledger::Entry.new(filing: filings(:lab900_dinner_filing), bank_transaction: nil)
    income   = Ledger::Entry.new(filing: filings(:lab900_april_filing),  bank_transaction: nil)
    tax      = Ledger::Entry.new(filing: filings(:modelo_303_filing),    bank_transaction: nil)

    assert_equal "Expense", ledger_kind_label(expense)
    assert_equal "Income",  ledger_kind_label(income)
    assert_equal "Tax",     ledger_kind_label(tax)
  end
end
