# Tray actions are quiet, non-navigational. v1 redirects back to / and lets
# Turbo follow the redirect — the page refreshes calmly without a full
# reload. If this proves janky in practice, swap for explicit Turbo Streams
# (remove the tray item + prepend a stream entry).
class TrayController < ApplicationController
  layout "app"

  def classify
    filing = Filing.find(params[:filing_id])
    filing.classify_into!(params[:folder])
    redirect_to home_path, notice: "Filed in #{filing.folder}."
  end
end
