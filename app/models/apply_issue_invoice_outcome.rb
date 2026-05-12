# Applies the terminal outcome of an issue_invoice Operation to its
# IssuedInvoice. Succeeded → sets status sent, copies refs.
# Aborted → flips Filing to needs_review so it surfaces on the review page.
class ApplyIssueInvoiceOutcome
  class << self
    def call(operation)
      Runtime::Assert.invariant!(operation.kind == "issue_invoice",
        "ApplyIssueInvoiceOutcome: wrong kind #{operation.kind.inspect}")
      Runtime::Assert.invariant!(operation.terminal?,
        "ApplyIssueInvoiceOutcome: operation not terminal (status=#{operation.status})")

      invoice = IssuedInvoice.find_by(id: operation.input["invoice_id"])
      return if invoice.nil?  # invoice deleted between enqueue and now

      if operation.status == "succeeded"
        apply_success(invoice, operation)
      else
        apply_abort(invoice)
      end
    end

    private

    def apply_success(invoice, operation)
      output = operation.output
      invoice.update!(
        invoice_status: "sent",
        verifactu_ref:  output["verifactu_ref"]
      )
      invoice.filing&.update!(
        status:     "filed",
        filed_at:   Time.current,
        holded_ref: output["provider_ref"]
      )
    end

    def apply_abort(invoice)
      invoice.update!(invoice_status: "draft")
      invoice.filing&.update!(status: "needs_review")
    end
  end
end
