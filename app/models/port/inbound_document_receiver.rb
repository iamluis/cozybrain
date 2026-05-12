# Port for classifying an inbound document (an email + an attachment) into
# one of brain's known document kinds, and suggesting where to file it.
# Adapters bound to this port look at the email metadata and decide:
#
#   - what kind of document this is (email_invoice / bank_statement / tax_doc / corporate / other)
#   - confidence in that decision (0.0 – 1.0)
#   - which gestoría folder it belongs in (expenses / bank / tax / corporate)
#   - what period it relates to (default: today)
#
# The Heuristic adapter ships with this milestone. An LLM-backed adapter
# could replace it later for fuzzier classification without changing any
# feature code.
module Port
  module InboundDocumentReceiver
    INPUT_SHAPE = {
      "received_document_id" => Integer,
      "from"                 => String,
      "subject"              => String,
      "body"                 => String
    }.freeze

    OUTPUT_SHAPE = {
      "classified_kind"        => String,
      "confidence"             => Float,
      "suggested_folder"       => String,
      "suggested_period_year"  => Integer,
      "suggested_period_month" => Integer
    }.freeze

    module_function

    def assert_input!(input)
      Runtime::Assert.shape!(input, INPUT_SHAPE, where: "Port::InboundDocumentReceiver input")
    end

    def assert_output!(output)
      Runtime::Assert.shape!(output, OUTPUT_SHAPE, where: "Port::InboundDocumentReceiver output")
    end
  end
end
