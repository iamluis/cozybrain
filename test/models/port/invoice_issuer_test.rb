require "test_helper"

class Port::InvoiceIssuerTest < ActiveSupport::TestCase
  def valid_input
    {
      "invoice_id"           => 1,
      "number"               => "2026-0005",
      "client_id"            => 1,
      "client_legal_name"    => "Lab900",
      "service_period_start" => "2026-05-01",
      "service_period_end"   => "2026-05-31",
      "tax_treatment"        => "intra_eu_reverse_charge",
      "currency"             => "EUR",
      "subtotal_cents"       => 800_000,
      "tax_amount_cents"     => 0,
      "total_cents"          => 800_000,
      "line_items"           => [ { "description" => "Consulting", "quantity" => "170", "unit_amount_cents" => 5000 } ]
    }
  end

  def valid_output
    {
      "provider_ref"  => "p-1",
      "verifactu_ref" => "vf-1",
      "pdf_url"       => "data:application/pdf;base64,abc",
      "sent_at"       => Time.current.iso8601
    }
  end

  test "assert_input! passes for valid input" do
    assert_nothing_raised { Port::InvoiceIssuer.assert_input!(valid_input) }
  end

  test "assert_input! rejects missing keys" do
    assert_raises(Runtime::AssertionError) { Port::InvoiceIssuer.assert_input!(valid_input.except("client_legal_name")) }
  end

  test "assert_input! rejects wrong types" do
    bad = valid_input.merge("subtotal_cents" => "800000") # string instead of Integer
    assert_raises(Runtime::AssertionError) { Port::InvoiceIssuer.assert_input!(bad) }
  end

  test "assert_output! passes for valid output" do
    assert_nothing_raised { Port::InvoiceIssuer.assert_output!(valid_output) }
  end

  test "assert_output! rejects missing pdf_url" do
    assert_raises(Runtime::AssertionError) { Port::InvoiceIssuer.assert_output!(valid_output.except("pdf_url")) }
  end
end
