require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "legal_name is required and unique" do
    c = Client.new(default_tax_treatment: "exempt")
    refute c.valid?
    assert_includes c.errors[:legal_name], "can't be blank"

    Client.create!(legal_name: "Acme", default_tax_treatment: "exempt")
    dup = Client.new(legal_name: "Acme", default_tax_treatment: "exempt")
    refute dup.valid?
    assert_includes dup.errors[:legal_name], "has already been taken"
  end

  test "default_tax_treatment must be one of TAX_TREATMENTS" do
    c = Client.new(legal_name: "X", default_tax_treatment: "bogus")
    refute c.valid?
    assert_includes c.errors[:default_tax_treatment].first, "included"
  end

  test "country must be a 2-letter ISO code if given" do
    c = Client.new(legal_name: "X", default_tax_treatment: "exempt", country: "ESP")
    refute c.valid?
    assert_match(/length/i, c.errors[:country].first)
  end

  test "Lab900 fixture loads with expected defaults" do
    c = clients(:lab900)
    assert_equal "Lab900",                   c.legal_name
    assert_equal "BE",                       c.country
    assert_equal "intra_eu_reverse_charge",  c.default_tax_treatment
    assert_equal 30,                         c.default_payment_terms_days
  end
end
