require "test_helper"

# End-to-end smoke test: an issue_invoice Operation dispatched via the
# Null adapter applies the success outcome to the IssuedInvoice and its
# Filing. Validates that 0007 + 0008 wire together.
class IssueInvoiceEndToEndTest < ActiveJob::TestCase
  test "succeeded operation marks invoice sent, files Filing, stores refs" do
    invoice = issued_invoices(:lab900_may_draft)

    op = Operation.create!(
      kind:          "issue_invoice",
      adapter_name:  Adapter::Null::InvoiceIssuer.name,
      max_attempts:  3,
      input: {
        "invoice_id"           => invoice.id,
        "number"               => invoice.number,
        "client_id"            => invoice.client_id,
        "client_legal_name"    => invoice.client.legal_name,
        "service_period_start" => invoice.service_period_start.iso8601,
        "service_period_end"   => invoice.service_period_end.iso8601,
        "tax_treatment"        => invoice.effective_tax_treatment,
        "currency"             => invoice.currency,
        "subtotal_cents"       => invoice.subtotal_cents,
        "tax_amount_cents"     => invoice.tax_amount_cents,
        "total_cents"          => invoice.total_cents,
        "line_items"           => invoice.line_items.map { |li|
          { "description" => li.description, "quantity" => li.quantity.to_s, "unit_amount_cents" => li.unit_amount_cents }
        }
      }
    )

    OperationJob.perform_now(op.id)

    op.reload
    assert_equal "succeeded", op.status

    invoice.reload
    assert_equal "sent", invoice.invoice_status
    assert invoice.verifactu_ref.start_with?("vf-null-")

    assert_equal "filed", invoice.filing.reload.status
    assert invoice.filing.filed_at.present?
    assert invoice.filing.holded_ref.start_with?("null-inv-")
  end
end
