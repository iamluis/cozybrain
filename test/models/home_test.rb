require "test_helper"

class HomeTest < ActiveSupport::TestCase
  def proof_sides(entries) = entries.filter_map(&:proof_side)
  def money_sides(entries) = entries.filter_map(&:money_side)

  test "stream contains proven entries (filed filings + matched bank tx as one event)" do
    home = Home.new

    assert_includes proof_sides(home.stream_entries), filings(:ryanair_filing)
    assert_includes proof_sides(home.stream_entries), filings(:santander_filing)
    assert_includes proof_sides(home.stream_entries), filings(:lab900_april_filing)
    assert_includes proof_sides(home.stream_entries), filings(:lab900_dinner_filing)
    # The matched bank tx is paired with its filing in one Ledger::Entry —
    # not a separate stream row.
    assert_equal 1, home.stream_entries.count { |e| e.money_side == bank_transactions(:dinner_charge) }
  end

  test "stream excludes needs_review filings and draft invoice filings" do
    home = Home.new

    refute_includes proof_sides(home.stream_entries), filings(:modelo_303_filing)
    refute_includes proof_sides(home.stream_entries), filings(:lab900_may_draft_filing)
  end

  test "tray gathers needs_review filings + draft invoices + unmatched transactions" do
    home = Home.new

    assert_includes proof_sides(home.tray_entries), filings(:modelo_303_filing)
    assert_includes proof_sides(home.tray_entries), filings(:lab900_may_draft_filing)
    assert_includes money_sides(home.tray_entries), bank_transactions(:parking_charge)
    assert_includes money_sides(home.tray_entries), bank_transactions(:mystery_charge)
    assert_includes money_sides(home.tray_entries), bank_transactions(:lab900_payment)
  end

  test "stream groups entries by day" do
    grouped = Home.new.stream_entries_by_day

    assert_kind_of Hash, grouped
    grouped.each_key { |k| assert_kind_of Date, k }
  end

  test "tray_count == entries + overflow" do
    home = Home.new
    assert_equal home.tray_entries.size + home.tray_overflow, home.tray_count
  end

  test "dismissed bank transaction does not appear in tray" do
    bank_transactions(:parking_charge).dismiss!
    home = Home.new
    refute_includes money_sides(home.tray_entries), bank_transactions(:parking_charge)
  end
end
