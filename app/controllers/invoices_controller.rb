class InvoicesController < ApplicationController
  layout "app"

  before_action :set_invoice, only: %i[ show update send_to_client ]

  def index
    @draft       = IssuedInvoice.where(invoice_status: "draft").order(created_at: :desc).first
    @historical  = IssuedInvoice.where.not(invoice_status: "draft").order(period_year: :desc, period_month: :desc)
    @next_period = next_period_after(@historical.first || @draft)
  end

  def create
    period   = period_for_new_draft
    # v1: a single client (Lab900). Picker on the form lands later when
    # there's more than one. For now we default to the most-recent invoice's
    # client, falling back to the first client in the system.
    last_inv = IssuedInvoice.order(period_year: :desc, period_month: :desc).first
    client   = last_inv&.client || Client.first
    unless client
      redirect_to invoices_path, alert: "Add a client first" and return
    end

    draft = IssuedInvoice.draft_next(
      user:         Current.user,
      client:       client,
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
  end

  def update
    refuse_unless_draft and return

    if @invoice.update(invoice_params)
      @invoice.recompute_total!
      # No flash here — the Stimulus controller updates an in-header
      # "Saved · HH:MM" pill via turbo:submit-end. Setting a flash on
      # every auto-save submit would shift the layout on every keystroke.
      redirect_to invoice_path(@invoice)
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
        "invoice_id"           => @invoice.id,
        "number"               => @invoice.number,
        "client_id"            => @invoice.client_id,
        "client_legal_name"    => @invoice.client.legal_name,
        "client_vat_number"    => @invoice.client.vat_number,
        "service_period_start" => @invoice.service_period_start&.iso8601,
        "service_period_end"   => @invoice.service_period_end&.iso8601,
        "tax_treatment"        => @invoice.effective_tax_treatment,
        "currency"             => @invoice.currency,
        "subtotal_cents"       => @invoice.subtotal_cents,
        "tax_amount_cents"     => @invoice.tax_amount_cents,
        "total_cents"          => @invoice.total_cents,
        "line_items"           => @invoice.line_items.map { |li|
          { "description" => li.description, "quantity" => li.quantity.to_s, "unit_amount_cents" => li.unit_amount_cents }
        }
      }
    )

    OperationJob.perform_later(operation.id)

    # Freeze the client legal name onto the invoice so future name changes
    # don't rewrite history.
    @invoice.update!(
      invoice_status: "approved",
      issued_on:      Date.current,
      client_name:    @invoice.client.legal_name
    )
    redirect_to invoice_path(@invoice), notice: "Sending…"
  end

  private

  def set_invoice
    @invoice = IssuedInvoice.includes(:line_items, :filing, :client).find(params[:id])
  end

  def refuse_unless_draft
    return false if @invoice.invoice_draft?
    redirect_to invoice_path(@invoice), alert: "This invoice has already been sent."
    true
  end

  def invoice_params
    params.expect(issued_invoice: [
      :client_id,
      :service_period_start,
      :service_period_end,
      :tax_treatment,
      :payment_terms_days,
      :iban_override,
      :notes,
      line_items_attributes: [ [ :id, :position, :description, :quantity, :unit_amount, :unit_amount_cents, :_destroy ] ]
    ])
  end

  def period_for_new_draft
    if params[:period_year].present? && params[:period_month].present?
      [ params[:period_year].to_i, params[:period_month].to_i ]
    else
      next_period_after(IssuedInvoice.order(period_year: :desc, period_month: :desc).first)
    end
  end

  def next_period_after(invoice)
    base = invoice ? Date.new(invoice.period_year, invoice.period_month, 1) : Date.current.beginning_of_month
    nxt  = base.next_month
    [ nxt.year, nxt.month ]
  end
end
