require "test_helper"

class HomeTest < ActiveSupport::TestCase
  test "stream contains filed filings + matched bank transactions" do
    home = Home.new

    assert_includes home.stream_events, filings(:ryanair_filing)
    assert_includes home.stream_events, filings(:santander_filing)
    assert_includes home.stream_events, filings(:lab900_april_filing)
    assert_includes home.stream_events, filings(:lab900_dinner_filing)
    assert_includes home.stream_events, bank_transactions(:dinner_charge)
  end

  test "stream excludes needs_review filings and draft invoice filings" do
    home = Home.new

    refute_includes home.stream_events, filings(:modelo_303_filing)
    refute_includes home.stream_events, filings(:lab900_may_draft_filing)
  end

  test "tray gathers needs_review filings + draft invoices + unmatched transactions" do
    home = Home.new

    assert_includes home.tray_items, filings(:modelo_303_filing)
    assert_includes home.tray_items, issued_invoices(:lab900_may_draft)
    assert_includes home.tray_items, bank_transactions(:parking_charge)
    assert_includes home.tray_items, bank_transactions(:mystery_charge)
    assert_includes home.tray_items, bank_transactions(:lab900_payment)
  end

  test "stream groups events by day" do
    grouped = Home.new.stream_events_by_day

    assert_kind_of Hash, grouped
    grouped.each_key { |k| assert_kind_of Date, k }
  end

  test "tray_count == items + overflow" do
    home = Home.new
    assert_equal home.tray_items.size + home.tray_overflow, home.tray_count
  end
end
