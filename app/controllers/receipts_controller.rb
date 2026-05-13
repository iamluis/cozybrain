class ReceiptsController < ApplicationController
  layout "app"

  before_action :set_receipt, only: %i[ show edit update ]

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
    fresh_when(@receipt, etag: [ @receipt, @receipt.filing ])
  end

  def edit
    fresh_when(@receipt, etag: [ @receipt, @receipt.filing ])
  end

  def update
    if @receipt.update(receipt_attributes) && update_note
      redirect_to receipt_path(@receipt), notice: "Saved"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_receipt
    @receipt = Receipt.includes(:filing).find(params[:id])
  end

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

  # Filing.note is on the wrapping Filing, not the Receipt — sync it from
  # the same form's :note param.
  def update_note
    note = params.dig(:receipt, :note)
    return true if note.nil?
    @receipt.filing.update(note: note.presence)
  end
end
