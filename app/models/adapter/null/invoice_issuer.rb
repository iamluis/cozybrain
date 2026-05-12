# Null implementation of Port::InvoiceIssuer. Returns synthetic
# provider/VeriFactu refs and a data-URL placeholder PDF. The default
# binding until Adapter::Holded::InvoiceIssuer ships in milestone 0013.
module Adapter
  module Null
    class InvoiceIssuer < Adapter::Base
      class << self
        def port_module
          Port::InvoiceIssuer
        end

        def _perform(_input)
          {
            "provider_ref"  => "null-inv-#{SecureRandom.hex(8)}",
            "verifactu_ref" => "vf-null-#{SecureRandom.hex(6)}",
            "pdf_url"       => "data:application/pdf;base64,JVBERi0xLjQK",
            "sent_at"       => Time.current.iso8601
          }
        end
      end
    end
  end
end
