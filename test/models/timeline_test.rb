require "test_helper"

class TimelineTest < ActiveSupport::TestCase
  test "merges filings and bank transactions into a single stream" do
    timeline = Timeline.recent
    assert_includes timeline.events, filings(:lab900_dinner_filing)
    assert_includes timeline.events, bank_transactions(:dinner_charge)
  end

  test "orders events newest first" do
    timeline = Timeline.recent
    timestamps = timeline.events.map { |e| timeline.timestamp_of(e) }
    assert_equal timestamps, timestamps.sort.reverse
  end

  test "excludes trashed filings" do
    f = filings(:lab900_dinner_filing)
    f.update!(trashed_at: Time.current)
    refute_includes Timeline.recent.events, f
  end

  test "events_by_day groups by Date" do
    grouped = Timeline.recent.events_by_day
    grouped.each_key { |k| assert_kind_of Date, k }
    grouped.each_value { |events| assert events.any? }
  end

  test "empty? is true when nothing exists" do
    BankTransaction.delete_all
    Filing.delete_all
    assert Timeline.recent.empty?
  end

  test "respects limit" do
    timeline = Timeline.recent(limit: 2)
    assert_operator timeline.events.size, :<=, 2
  end
end
