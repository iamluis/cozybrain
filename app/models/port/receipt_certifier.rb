# Port for receipt certification. Adapters bound to this port take a captured
# receipt photo and return a legally-certified PDF + a provider reference for
# audit trail. The Spanish AEAT-homologated certification process is the
# motivating use case (Holded, Verifacti); other adapters could exist.
module Port
  module ReceiptCertifier
    INPUT_SHAPE = {
      "receipt_id" => Integer,
      "photo_url"  => String
    }.freeze

    OUTPUT_SHAPE = {
      "certified_pdf_url" => String,
      "provider_ref"      => String
    }.freeze

    module_function

    def assert_input!(input)
      Runtime::Assert.shape!(input, INPUT_SHAPE, where: "Port::ReceiptCertifier input")
    end

    def assert_output!(output)
      Runtime::Assert.shape!(output, OUTPUT_SHAPE, where: "Port::ReceiptCertifier output")
    end
  end
end
