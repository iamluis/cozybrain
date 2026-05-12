# InboxMailbox is brain's only inbound-mail surface.
#
# Per email: for each attachment, create one ReceivedDocument + its
# Filing (status pending, folder expenses, source email), then enqueue a
# deliver_inbound_document Operation so the bound adapter classifies it
# (kind, folder, period) without blocking mail delivery. Emails with no
# attachments are recorded as their own ReceivedDocument with the body
# as the artefact.
#
# This is the *receive* side of the spine: persist what arrived, then
# defer interpretation to the runtime.
class InboxMailbox < ApplicationMailbox
  def process
    user = User.first
    Runtime::Assert.invariant!(!user.nil?, "InboxMailbox: no User to attribute inbound mail to")

    documents = build_documents(user)
    Runtime::Assert.invariant!(documents.any?, "InboxMailbox: build_documents returned empty for #{inbound_email.id}")

    documents.each { |doc| enqueue_classification(doc) }
  end

  private

  def build_documents(user)
    if mail.attachments.any?
      mail.attachments.map { |attachment| build_document_for(attachment, user) }
    else
      [ build_document_for_body(user) ]
    end
  end

  def build_document_for(attachment, user)
    doc = ReceivedDocument.new(
      kind:    "other",
      sender:  mail.from&.first,
      subject: mail.subject
    )
    doc.original.attach(
      io:           StringIO.new(attachment.body.decoded),
      filename:     attachment.filename,
      content_type: attachment.content_type
    )
    doc.build_filing(filing_attrs(user))
    doc.save!
    doc
  end

  def build_document_for_body(user)
    doc = ReceivedDocument.new(
      kind:    "other",
      sender:  mail.from&.first,
      subject: mail.subject
    )
    doc.original.attach(
      io:           StringIO.new(mail.body.to_s),
      filename:     "email.txt",
      content_type: "text/plain"
    )
    doc.build_filing(filing_attrs(user))
    doc.save!
    doc
  end

  def filing_attrs(user)
    today = Date.current
    {
      user:         user,
      folder:       "expenses",
      period_year:  today.year,
      period_month: today.month,
      status:       "pending",
      source:       "email",
      received_at:  Time.current,
      note:         "from #{mail.from&.first}: #{mail.subject}"
    }
  end

  def enqueue_classification(doc)
    adapter = Runtime::Dispatcher.adapter_for(Port::InboundDocumentReceiver)
    op = Operation.create!(
      kind:           "deliver_inbound_document",
      adapter_name:   adapter.name,
      correlation_id: "ReceivedDocument:#{doc.id}",
      max_attempts:   3,
      input: {
        "received_document_id" => doc.id,
        "from"                 => mail.from&.first.to_s,
        "subject"              => mail.subject.to_s,
        "body"                 => mail.body.to_s.first(2000)
      }
    )
    OperationJob.perform_later(op.id)
  end
end
