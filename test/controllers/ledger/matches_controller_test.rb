require "test_helper"

class Ledger::MatchesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:luis)) }

  test "GET /ledger/matches/new lists candidate filings within tolerance" do
    # parking_charge is €-4.50 on 2026-05-09. parking_meter receipt is on
    # 2026-05-09. Should appear as a candidate.
    get new_ledger_match_path(bank_transaction_id: bank_transactions(:parking_charge).id)
    assert_response :success
    # Candidate row for the parking-meter receipt should be present.
    assert_select ".match__row-title", text: /Parking|Receipt|parking/i
  end

  test "POST /ledger/matches links the bank tx to the filing" do
    txn    = bank_transactions(:parking_charge)
    filing = filings(:parking_meter_filing)

    post ledger_matches_path, params: { bank_transaction_id: txn.id, filing_id: filing.id }

    assert_equal filing, txn.reload.matched_filing
    assert_redirected_to home_path
  end

  test "POST /ledger/dismissals marks the bank tx dismissed" do
    txn = bank_transactions(:parking_charge)
    post ledger_dismissals_path, params: { bank_transaction_id: txn.id }
    assert txn.reload.dismissed?
    assert_redirected_to home_path
  end
end
