class Timeline
  DEFAULT_LIMIT = 100

  attr_reader :events

  def self.recent(limit: DEFAULT_LIMIT)
    new(limit: limit)
  end

  def initialize(limit: DEFAULT_LIMIT)
    filings      = Filing.untrashed.includes(:filable).order(received_at: :desc).limit(limit)
    transactions = BankTransaction.includes(:matched_filing).order(posted_on: :desc, created_at: :desc).limit(limit)

    @events = (filings.to_a + transactions.to_a)
                .sort_by { |e| -timestamp_of(e).to_i }
                .first(limit)
  end

  def events_by_day
    events.group_by { |e| timestamp_of(e).to_date }
  end

  def empty?
    events.empty?
  end

  def timestamp_of(event)
    case event
    when Filing          then event.received_at
    when BankTransaction then event.posted_on.to_time.end_of_day
    end
  end
end
