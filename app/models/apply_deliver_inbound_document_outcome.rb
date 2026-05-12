# Applies the terminal outcome of a deliver_inbound_document Operation
# to its ReceivedDocument + Filing.
#
# Success: copy classifier output onto the doc (kind) and filing
# (folder, period, status). Confidence below the threshold → status
# needs_review (the classifier hedged, ask the human).
# Abort: filing → needs_review with the error message in the note.
class ApplyDeliverInboundDocumentOutcome
  CONFIDENT_THRESHOLD = 0.6

  class << self
    def call(operation)
      Runtime::Assert.invariant!(operation.kind == "deliver_inbound_document",
        "ApplyDeliverInboundDocumentOutcome: wrong kind #{operation.kind.inspect}")
      Runtime::Assert.invariant!(operation.terminal?,
        "ApplyDeliverInboundDocumentOutcome: operation not terminal (status=#{operation.status})")

      doc = ReceivedDocument.find_by(id: operation.input["received_document_id"])
      return if doc.nil?

      operation.status == "succeeded" ? apply_success(doc, operation) : apply_abort(doc, operation)
    end

    private

    def apply_success(doc, operation)
      output     = operation.output
      kind       = output["classified_kind"]
      confident  = output["confidence"] >= CONFIDENT_THRESHOLD
      next_status = confident ? "filed" : "needs_review"

      doc.update!(kind: kind)
      doc.filing.update!(
        folder:       output["suggested_folder"],
        period_year:  output["suggested_period_year"],
        period_month: output["suggested_period_month"],
        status:       next_status,
        filed_at:     confident ? Time.current : nil
      )
    end

    def apply_abort(doc, operation)
      doc.filing.update!(
        status: "needs_review",
        note:   "classification failed: #{operation.error}"
      )
    end
  end
end
