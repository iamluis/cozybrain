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
    filings = Filing.untrashed.to_a
    preload_polymorphic_targets!(filings)

    transactions = BankTransaction.active.includes(:matched_filing).to_a

    paired_txn_ids = filings.filter_map { |f| f.matched_bank_transaction&.id }.to_set

    entries = filings.map { |f| Ledger::Entry.from_filing(f) }
    transactions.each do |t|
      next if paired_txn_ids.include?(t.id)
      entries << Ledger::Entry.from_bank_transaction(t)
    end
    entries
  end

  # Polymorphic includes (:filable) can't drill into filable-specific
  # associations. Hand-roll: preload filable + bank_tx, then per-type
  # preload the deeper stuff (Active Storage for Receipts, Client for
  # IssuedInvoices). Cuts ~100 queries off a 400-filing /home render.
  def preload_polymorphic_targets!(filings)
    ActiveRecord::Associations::Preloader.new(
      records: filings,
      associations: [ :filable, :matched_bank_transaction ]
    ).call

    by_type = filings.group_by(&:filable_type)

    if (receipts = by_type["Receipt"]&.map(&:filable))
      ActiveRecord::Associations::Preloader.new(
        records: receipts,
        associations: { original_photo_attachment: :blob }
      ).call
    end

    if (invoices = by_type["IssuedInvoice"]&.map(&:filable))
      ActiveRecord::Associations::Preloader.new(
        records: invoices,
        associations: :client
      ).call
    end
  end
end
