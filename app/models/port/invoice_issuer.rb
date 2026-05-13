# Port for issuing an invoice to a client through a compliance-aware
# provider. Adapters bound to this port submit the invoice (incl. VAT
# compliance — VeriFactu in Spain), receive back a provider reference, a
# VeriFactu reference, and a URL to the legally-binding PDF.
module Port
  module InvoiceIssuer
    INPUT_SHAPE = {
      "invoice_id"           => Integer,
      "number"               => String,
      "client_id"            => Integer,
      "client_legal_name"    => String,
      "service_period_start" => String,
      "service_period_end"   => String,
      "tax_treatment"        => String,
      "currency"             => String,
      "subtotal_cents"       => Integer,
      "tax_amount_cents"     => Integer,
      "total_cents"          => Integer,
      "line_items"           => Array
    }.freeze

    OUTPUT_SHAPE = {
      "provider_ref"  => String,
      "verifactu_ref" => String,
      "pdf_url"       => String,
      "sent_at"       => String
    }.freeze

    module_function

    def assert_input!(input)
      Runtime::Assert.shape!(input, INPUT_SHAPE, where: "Port::InvoiceIssuer input")
    end

    def assert_output!(output)
      Runtime::Assert.shape!(output, OUTPUT_SHAPE, where: "Port::InvoiceIssuer output")
    end
  end
end
