require "test_helper"

class InboxMailboxTest < ActionMailbox::TestCase
  setup do
    # Ensure a user exists for inbox attribution
    @user = users(:luis)
  end

  def deliver_email(from:, subject:, body: "see attached", attachment: nil)
    mail = Mail.new(from: from, to: "inbox@brain.local", subject: subject, body: body)

    if attachment
      mail.attachments[attachment[:filename]] = {
        mime_type: attachment[:content_type],
        content:   attachment[:body]
      }
    end

    receive_inbound_email_from_source(mail.to_s)
  end

  test "creates one ReceivedDocument per attachment" do
    assert_difference -> { ReceivedDocument.count } => 2, -> { Filing.count } => 2 do
      mail = Mail.new(from: "receipts@ryanair.com", to: "inbox@brain.local", subject: "Your Ryanair invoice", body: "see attached")
      mail.attachments["FR4521.pdf"]   = "fake pdf content"
      mail.attachments["receipt.html"] = "<html>receipt</html>"
      receive_inbound_email_from_source(mail.to_s)
    end

    doc = ReceivedDocument.order(:id).last
    assert_equal "receipts@ryanair.com", doc.sender
    assert_equal "email", doc.filing.source
    assert doc.original.attached?
  end

  test "enqueues a deliver_inbound_document Operation per attachment" do
    assert_difference -> { Operation.count } => 1 do
      mail = Mail.new(from: "receipts@ryanair.com", to: "inbox@brain.local", subject: "invoice", body: "see attached")
      mail.attachments["FR.pdf"] = "fake pdf"
      receive_inbound_email_from_source(mail.to_s)
    end

    op = Operation.order(:id).last
    assert_equal "deliver_inbound_document", op.kind
    assert_equal "pending",                  op.status
    assert_equal "Adapter::Heuristic::InboundDocumentReceiver", op.adapter_name
    assert_match(/ryanair/, op.input["from"])
  end

  test "emails without attachments still create a single document for the body" do
    assert_difference -> { ReceivedDocument.count } => 1 do
      mail = Mail.new(from: "gestoria@example.com", to: "inbox@brain.local", subject: "Modelo 303 Q1", body: "Body content here")
      receive_inbound_email_from_source(mail.to_s)
    end

    doc = ReceivedDocument.order(:id).last
    assert doc.original.attached?
    assert_equal "email.txt", doc.original.filename.to_s
  end
end
