require "test_helper"

class WeeklyPulseTest < ActiveSupport::TestCase
  # Fixtures center on early-mid May 2026.
  #   2026-05-04 Mon — start of ISO week
  #   2026-05-10 Sun — end of ISO week (Le Pain Quotidien dinner is in here)
  def anchor_in_dinner_week
    Time.zone.local(2026, 5, 7, 9, 0, 0)
  end

  test "period_label spans Monday to Sunday" do
    pulse = WeeklyPulse.new(at: anchor_in_dinner_week)
    assert_equal Date.new(2026, 5, 4), pulse.week_start
    assert_equal Date.new(2026, 5, 10), pulse.week_end
    assert_match(/4–10 May 2026/, pulse.period_label)
  end

  test "money_out sums the week's expenses" do
    pulse = WeeklyPulse.new(at: anchor_in_dinner_week)
    # The Le Pain Quotidien dinner (2350c) on 2026-05-08 falls in this
    # week. The parking_meter (450c) on 2026-05-09 also.
    assert pulse.money_out_cents.positive?
    assert_includes pulse.expense_entries.map { |e| e.proof_side.id },
                    filings(:lab900_dinner_filing).id
  end

  test "money_out_by_kind buckets by Ledger::Entry kind" do
    pulse = WeeklyPulse.new(at: anchor_in_dinner_week)
    refute pulse.money_out_by_kind.empty?
    pulse.money_out_by_kind.each_key { |k| assert_includes WeeklyPulse::KIND_BUCKETS, k }
  end

  test "needs_attention includes open tray entries" do
    pulse = WeeklyPulse.new(at: anchor_in_dinner_week)
    assert pulse.needs_attention.any?(&:open?)
  end

  test "MTD income / expense aggregate across the month so far" do
    pulse = WeeklyPulse.new(at: anchor_in_dinner_week)
    assert pulse.mtd_expense_cents.positive?
  end

  test "empty? is true when nothing happened" do
    Filing.update_all(trashed_at: Time.current)
    BankTransaction.update_all(dismissed_at: Time.current)
    assert WeeklyPulse.new(at: anchor_in_dinner_week).empty?
  end
end
