# GET /pulse — renders the current week's digest in HTML. Used directly
# by the user (one tap from Home) and rendered to plain text + HTML by
# the weekly job for the notification body.
class WeeklyPulsesController < ApplicationController
  layout "app"

  def show
    @pulse = WeeklyPulse.new(at: Time.current)
    fresh_when(
      last_modified: [
        Filing.maximum(:updated_at),
        IssuedInvoice.maximum(:updated_at),
        BankTransaction.maximum(:updated_at)
      ].compact.max,
      etag: [ @pulse.week_start, Filing.count, BankTransaction.count ],
      public: false
    )
  end
end
