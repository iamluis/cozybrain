# Composes the weekly digest for Luis: money in, money out (rough buckets),
# things needing attention, month-to-date totals. Pure read; no writes.
#
# Built for a given anchor `at` Time (defaults to Time.current). The pulse
# covers the ISO week containing that anchor (Mon–Sun).
class WeeklyPulse
  KIND_BUCKETS = %i[ expense tax corporate transfer ].freeze

  attr_reader :anchor, :week_start, :week_end

  def initialize(at: Time.current)
    @anchor     = at
    @week_start = at.to_date.beginning_of_week     # Monday
    @week_end   = at.to_date.end_of_week           # Sunday
  end

  def period_label
    if week_start.month == week_end.month
      "Week of #{I18n.l(week_start, format: '%-d')}–#{I18n.l(week_end, format: '%-d %B %Y')}"
    else
      "Week of #{I18n.l(week_start, format: '%-d %b')} – #{I18n.l(week_end, format: '%-d %b %Y')}"
    end
  end

  # --- Money in -----------------------------------------------------------

  def money_in_cents
    income_entries.sum { |e| e.amount_cents.to_i.abs }
  end

  def income_entries
    @income_entries ||= week_entries.select { |e| e.kind == :income }
  end

  # --- Money out ----------------------------------------------------------

  def money_out_cents
    expense_entries.sum { |e| e.amount_cents.to_i.abs }
  end

  def expense_entries
    @expense_entries ||= week_entries.select { |e| e.kind == :expense }
  end

  def money_out_by_kind
    KIND_BUCKETS.each_with_object({}) do |k, acc|
      entries = week_entries.select { |e| e.kind == k }
      next if entries.empty?
      acc[k] = entries.sum { |e| e.amount_cents.to_i.abs }
    end
  end

  # --- Needs attention ----------------------------------------------------

  def needs_attention
    @needs_attention ||= open_entries
  end

  def needs_attention_count
    needs_attention.size
  end

  # --- Month-to-date ------------------------------------------------------

  def mtd_income_cents
    month_entries.select { |e| e.kind == :income }.sum { |e| e.amount_cents.to_i.abs }
  end

  def mtd_expense_cents
    month_entries.select { |e| e.kind == :expense }.sum { |e| e.amount_cents.to_i.abs }
  end

  # --- Composition --------------------------------------------------------

  def empty?
    income_entries.empty? &&
      expense_entries.empty? &&
      needs_attention.empty?
  end

  private

  def week_entries
    @week_entries ||= all_entries.select { |e| e.proven? && e.at.between?(week_start, week_end) }
  end

  def month_entries
    @month_entries ||= all_entries.select { |e| e.proven? && e.at.between?(week_start.beginning_of_month, week_end) }
  end

  def open_entries
    all_entries.select(&:open?).sort_by { |e| -e.at.to_time.to_i }
  end

  def all_entries
    @all_entries ||= begin
      filings      = Filing.untrashed.includes(:filable, :matched_bank_transaction)
      transactions = BankTransaction.active.includes(:matched_filing)

      paired_txn_ids = Set.new
      entries = filings.map do |f|
        paired_txn_ids << f.matched_bank_transaction.id if f.matched_bank_transaction
        Ledger::Entry.from_filing(f)
      end
      transactions.each do |t|
        next if paired_txn_ids.include?(t.id)
        entries << Ledger::Entry.from_bank_transaction(t)
      end
      entries
    end
  end
end
