# GET /pulse — renders the current week's digest in HTML. Used directly
# by the user (one tap from Home) and rendered to plain text + HTML by
# the weekly job for the notification body.
class WeeklyPulsesController < ApplicationController
  layout "app"

  def show
    return unless stale?(
      last_modified: [
        Filing.maximum(:updated_at),
        IssuedInvoice.maximum(:updated_at),
        BankTransaction.maximum(:updated_at)
      ].compact.max,
      etag: [ Date.current.beginning_of_week, Filing.count, BankTransaction.count ],
      public: false
    )

    @pulse = WeeklyPulse.new(at: Time.current)
  end
end
