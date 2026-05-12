# Null implementation of Port::ReceiptCertifier — returns a synthetic
# data-URL PDF and a fake provider ref. Useful as the default binding
# until a real adapter (e.g., Adapter::Holded::ReceiptCertifier) ships.
module Adapter
  module Null
    class ReceiptCertifier < Adapter::Base
      class << self
        def port_module
          Port::ReceiptCertifier
        end

        def _perform(_input)
          {
            "certified_pdf_url" => "data:application/pdf;base64,JVBERi0xLjQK",
            "provider_ref"      => "null-#{SecureRandom.hex(8)}"
          }
        end
      end
    end
  end
end
