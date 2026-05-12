class TimelinesController < ApplicationController
  layout "app"

  def show
    @timeline = Timeline.recent
  end
end
