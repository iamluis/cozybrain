# Home is the single aggregate surface behind /. It composes two views over
# existing scopes:
#
#   stream — calm, day-grouped scroll of work that's *done*. Anything still
#            owed an attention slice lives in the tray instead.
#   tray   — small pile (hard-capped) of items that need a finger.
#
# The split rule: anything with `status: needs_review`, any draft invoice, and
# any unmatched bank transaction is *attention*. Everything else is *trust*.
class Home
  STREAM_LIMIT = 100
  TRAY_LIMIT   = 12

  attr_reader :stream_events, :tray_items, :tray_overflow

  def initialize
    @stream_events = load_stream
    tray, overflow = load_tray
    @tray_items    = tray
    @tray_overflow = overflow
  end

  def stream_empty? = stream_events.empty?
  def tray_empty?   = tray_items.empty?

  def stream_events_by_day
    stream_events.group_by { |e| stream_timestamp(e).to_date }
  end

  def tray_count
    tray_items.size + tray_overflow
  end

  private

  def load_stream
    filings = Filing.untrashed
                    .where.not(status: "needs_review")
                    .where.not(id: draft_invoice_filing_ids)
                    .includes(:filable)
                    .order(received_at: :desc)
                    .limit(STREAM_LIMIT)

    transactions = BankTransaction.matched
                                  .includes(:matched_filing)
                                  .order(posted_on: :desc, created_at: :desc)
                                  .limit(STREAM_LIMIT)

    (filings.to_a + transactions.to_a)
      .sort_by { |e| -stream_timestamp(e).to_i }
      .first(STREAM_LIMIT)
  end

  def load_tray
    items = []
    items.concat(Filing.needs_review.includes(:filable).order(received_at: :desc))
    items.concat(IssuedInvoice.includes(:filing).where(invoice_status: "draft").order(created_at: :desc))
    items.concat(BankTransaction.unmatched.order(posted_on: :desc).limit(TRAY_LIMIT))

    overflow = [ items.size - TRAY_LIMIT, 0 ].max
    [ items.first(TRAY_LIMIT), overflow ]
  end

  def draft_invoice_filing_ids
    @draft_invoice_filing_ids ||= IssuedInvoice.where(invoice_status: "draft").joins(:filing).pluck("filings.id")
  end

  def stream_timestamp(event)
    case event
    when Filing          then event.received_at
    when BankTransaction then event.posted_on.to_time.end_of_day
    end
  end
end
