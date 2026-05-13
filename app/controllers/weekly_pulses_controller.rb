# GET /pulse — renders the current week's digest in HTML. Used directly
# by the user (one tap from Home) and rendered to plain text + HTML by
# the weekly job for the notification body.
class WeeklyPulsesController < ApplicationController
  layout "app"

  def show
    @pulse = WeeklyPulse.new(at: Time.current)
  end
end
