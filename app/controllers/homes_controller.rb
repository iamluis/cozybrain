class HomesController < ApplicationController
  layout "app"

  def show
    # Compute the cheap etag/last-modified BEFORE building @home; if the
    # browser already has a current copy, return 304 without paying for
    # the polymorphic preloads or the entry composition.
    return unless stale?(
      last_modified: home_last_modified,
      etag:          home_etag,
      public:        false
    )

    @home = Home.new
  end

  private

  # Most recent change to anything that affects the stream/tray —
  # filings, invoices, bank transactions. If none of these have moved,
  # the page is unchanged and the browser gets a 304.
  def home_last_modified
    [
      Filing.maximum(:updated_at),
      IssuedInvoice.maximum(:updated_at),
      BankTransaction.maximum(:updated_at)
    ].compact.max
  end

  def home_etag
    [
      Filing.maximum(:updated_at)&.to_i,
      Filing.count,
      IssuedInvoice.maximum(:updated_at)&.to_i,
      BankTransaction.maximum(:updated_at)&.to_i,
      BankTransaction.count
    ]
  end
end
