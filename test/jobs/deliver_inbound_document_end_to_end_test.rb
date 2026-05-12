require "test_helper"

# End-to-end smoke test: an inbound mail (Ryanair invoice) produces a
# ReceivedDocument, dispatches via Heuristic adapter, applies the
# success outcome — final state: kind email_invoice, folder expenses,
# status filed.
class DeliverInboundDocumentEndToEndTest < ActionMailbox::TestCase
  include ActiveJob::TestHelper

  test "Ryanair attachment lands as filed email_invoice in expenses" do
    mail = Mail.new(from: "receipts@ryanair.com", to: "inbox@brain.local", subject: "Your Ryanair invoice FR4521-2026", body: "see attached")
    mail.attachments["FR4521.pdf"] = "fake pdf bytes"
    receive_inbound_email_from_source(mail.to_s)

    perform_enqueued_jobs

    doc = ReceivedDocument.order(:id).last
    assert_equal "email_invoice", doc.reload.kind
    assert_equal "expenses",      doc.filing.reload.folder
    assert_equal "filed",         doc.filing.status
    assert doc.filing.filed_at.present?
  end

  test "unrecognized sender lands as needs_review (low confidence)" do
    mail = Mail.new(from: "random@nobody.com", to: "inbox@brain.local", subject: "hey", body: "?")
    mail.attachments["thing.pdf"] = "fake"
    receive_inbound_email_from_source(mail.to_s)

    perform_enqueued_jobs

    doc = ReceivedDocument.order(:id).last
    assert_equal "other",        doc.reload.kind
    assert_equal "needs_review", doc.filing.reload.status
    assert_nil doc.filing.filed_at
  end
end
