require "test_helper"

class Adapter::Heuristic::InboundDocumentReceiverTest < ActiveSupport::TestCase
  def call(from:, subject:, body: "")
    Adapter::Heuristic::InboundDocumentReceiver.call(
      "received_document_id" => 1,
      "from"                 => from,
      "subject"              => subject,
      "body"                 => body
    )
  end

  test "classifies Ryanair invoices into expenses with high confidence" do
    out = call(from: "receipts@ryanair.com", subject: "Your Ryanair invoice FR4521-2026")
    assert_equal "email_invoice", out["classified_kind"]
    assert_equal "expenses",      out["suggested_folder"]
    assert out["confidence"] >= 0.7
  end

  test "classifies bank statements into bank" do
    out = call(from: "noreply@santander.es", subject: "Extracto cuenta empresa - Mayo 2026")
    assert_equal "bank_statement", out["classified_kind"]
    assert_equal "bank",           out["suggested_folder"]
  end

  test "classifies tax docs into tax" do
    out = call(from: "gestoria@example.com", subject: "Modelo 303 Q1 2026")
    assert_equal "tax_doc", out["classified_kind"]
    assert_equal "tax",     out["suggested_folder"]
  end

  test "classifies corporate docs into corporate" do
    out = call(from: "registro@example.es", subject: "Escritura de constitución")
    assert_equal "corporate", out["classified_kind"]
    assert_equal "corporate", out["suggested_folder"]
  end

  test "falls back to other with low confidence when nothing matches" do
    out = call(from: "random@nobody.com", subject: "hey")
    assert_equal "other", out["classified_kind"]
    assert_in_delta 0.3, out["confidence"], 0.01
  end

  test "output passes Port::InboundDocumentReceiver shape assertions" do
    out = call(from: "x@y.com", subject: "anything")
    assert_nothing_raised { Port::InboundDocumentReceiver.assert_output!(out) }
  end
end
