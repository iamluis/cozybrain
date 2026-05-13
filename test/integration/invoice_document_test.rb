require "test_helper"

# Renders the invoice document (sent view) and asserts that the right
# legal mentions + footer blocks land for each tax treatment.
class InvoiceDocumentTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:luis)) }

  test "sent invoice with intra_eu_reverse_charge shows Art. 196 mention" do
    invoice = issued_invoices(:lab900_april)
    get invoice_path(invoice)
    assert_response :success
    assert_select ".invoice__legal", text: /Inversi.n del sujeto pasivo.*Art\. 196/i
    assert_select ".invoice__totals-row", text: /Subtotal/
    assert_select ".invoice__totals-row--total", text: /Total/
    assert_select ".invoice__totals-row", text: /IVA 21/, count: 0
  end

  test "sent invoice with domestic_vat_21 shows IVA 21% row and no reverse-charge legal" do
    invoice = issued_invoices(:lab900_april)
    invoice.update!(tax_treatment: "domestic_vat_21")
    invoice.recompute_total!

    get invoice_path(invoice)
    assert_response :success
    assert_select ".invoice__totals-row", text: /IVA 21/
    assert_select ".invoice__legal", false
  end

  test "sent invoice renders payment terms + IBAN block" do
    invoice = issued_invoices(:lab900_april)
    get invoice_path(invoice)
    assert_select ".invoice__payment-block", text: /Payment within 30 days/
    assert_select ".invoice__payment-block", text: /IBAN: ES1234567890123456789012/
  end
end
