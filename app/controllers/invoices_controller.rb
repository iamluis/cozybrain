class InvoicesController < ApplicationController
  layout "app"

  before_action :set_invoice, only: %i[ show update send_to_client ]

  def index
    @draft       = IssuedInvoice.where(invoice_status: "draft").order(created_at: :desc).first
    @historical  = IssuedInvoice.where.not(invoice_status: "draft").order(period_year: :desc, period_month: :desc)
    @next_period = next_period_after(@historical.first || @draft)
  end

  def create
    period = (params[:period_year] && params[:period_month]) \
      ? [ params[:period_year].to_i, params[:period_month].to_i ]
      : next_period_after(IssuedInvoice.order(period_year: :desc, period_month: :desc).first)

    draft = IssuedInvoice.draft_next(
      user:         Current.user,
      period_year:  period.first,
      period_month: period.last
    )

    if draft.save
      redirect_to invoice_path(draft)
    else
      redirect_to invoices_path, alert: draft.errors.full_messages.to_sentence
    end
  end

  def show
    # Draft view is editable; sent view is read-only. Same template branches.
  end

  def update
    refuse_unless_draft and return

    if @invoice.update(invoice_params)
      @invoice.recompute_total!
      redirect_to invoice_path(@invoice), notice: "Saved"
    else
      render :show, status: :unprocessable_content
    end
  end

  def send_to_client
    refuse_unless_draft and return

    @invoice.recompute_total!

    operation = Operation.create!(
      kind:            "issue_invoice",
      adapter_name:    Runtime::Dispatcher.adapter_for(Port::InvoiceIssuer).name,
      correlation_id:  "IssuedInvoice:#{@invoice.id}",
      max_attempts:    5,
      input: {
        "invoice_id"    => @invoice.id,
        "number"        => @invoice.number,
        "client_name"   => @invoice.client_name,
        "period_year"   => @invoice.period_year,
        "period_month"  => @invoice.period_month,
        "currency"      => @invoice.currency,
        "total_cents"   => @invoice.amount_cents,
        "line_items"    => @invoice.line_items.map { |li|
          { "description" => li.description, "quantity" => li.quantity.to_s, "unit_amount_cents" => li.unit_amount_cents }
        }
      }
    )

    OperationJob.perform_later(operation.id)

    @invoice.update!(invoice_status: "approved", issued_on: Date.current)
    redirect_to invoice_path(@invoice), notice: "Sending…"
  end

  private

  def set_invoice
    @invoice = IssuedInvoice.includes(:line_items, :filing).find(params[:id])
  end

  def refuse_unless_draft
    return false if @invoice.invoice_draft?
    redirect_to invoice_path(@invoice), alert: "This invoice has already been sent."
    true
  end

  def invoice_params
    params.expect(issued_invoice: [
      :client_name,
      line_items_attributes: [ [ :id, :position, :description, :quantity, :unit_amount_cents, :_destroy ] ]
    ])
  end

  def next_period_after(invoice)
    base = invoice ? Date.new(invoice.period_year, invoice.period_month, 1) : Date.current.beginning_of_month
    nxt  = base.next_month
    [ nxt.year, nxt.month ]
  end
end
