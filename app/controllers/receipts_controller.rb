class ReceiptsController < ApplicationController
  layout "app"

  def new
    @receipt = Receipt.new(paid_on: Date.current, currency: "EUR")
  end

  def create
    @receipt = build_receipt
    if @receipt.save
      redirect_to @receipt
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    @receipt = Receipt.find(params[:id])
  end

  private

  def build_receipt
    receipt = Receipt.new(receipt_attributes)
    receipt.currency ||= "EUR"
    paid = receipt.paid_on || Date.current
    receipt.build_filing(
      user: Current.user,
      folder: "expenses",
      period_year: paid.year,
      period_month: paid.month,
      status: "pending",
      source: "capture",
      received_at: Time.current,
      note: filing_note
    )
    receipt
  end

  def receipt_attributes
    params.expect(receipt: [ :amount, :paid_on, :vendor, :country, :original_photo ])
  end

  def filing_note
    params.dig(:receipt, :note).presence
  end
end
