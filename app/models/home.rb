# Home composes the user's day into Ledger::Entry rows, split into two
# surfaces:
#
#   stream — calm, day-grouped scroll of *proven* entries.
#   tray   — small pile (hard-capped) of *open* entries that want a finger.
#
# `Filing.trashed_at` and `BankTransaction.dismissed_at` keep entries out
# of both surfaces.
class Home
  STREAM_LIMIT = 100
  TRAY_LIMIT   = 12

  attr_reader :stream_entries, :tray_entries, :tray_overflow

  def initialize
    all = load_entries
    @stream_entries = all.select(&:proven?).sort_by { |e| -e.at.to_time.to_i }.first(STREAM_LIMIT)
    tray            = all.select(&:open?).sort_by    { |e| -e.at.to_time.to_i }
    @tray_entries   = tray.first(TRAY_LIMIT)
    @tray_overflow  = [ tray.size - TRAY_LIMIT, 0 ].max
  end

  def stream_empty? = stream_entries.empty?
  def tray_empty?   = tray_entries.empty?

  def stream_entries_by_day
    stream_entries.group_by(&:at)
  end

  def tray_count
    tray_entries.size + tray_overflow
  end

  private

  # Pull every Filing + every BankTransaction that's still active, wrap each
  # one in a Ledger::Entry, and de-dupe pairs (a matched bank tx + its
  # filing are one event, not two).
  def load_entries
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
