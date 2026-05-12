class InvoicesController < ApplicationController
  layout "app"

  def index
    @invoices = IssuedInvoice.order(period_year: :desc, period_month: :desc)
  end
end
