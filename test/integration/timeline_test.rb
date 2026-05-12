require "test_helper"

class TimelineIntegrationTest < ActionDispatch::IntegrationTest
  setup { @user = users(:luis) }

  test "redirects unauthenticated users to sign in" do
    get timeline_path
    assert_redirected_to new_session_path
  end

  test "signed-in root redirects to timeline" do
    sign_in_as(@user)
    get root_path
    assert_redirected_to timeline_path
  end

  test "renders inside app shell with day groups and entries" do
    sign_in_as(@user)
    get timeline_path

    assert_response :success
    assert_select "header.shell__header"
    assert_select "h1", text: "Activity"
    assert_select "section.timeline__day"
    assert_select "section.timeline__day h2.timeline__day-label"
    assert_select "li.timeline__entry"
  end

  test "renders Receipt entry with vendor and signed amount" do
    sign_in_as(@user)
    get timeline_path

    assert_select "li.timeline__entry .entry__title", text: /Le Pain Quotidien/
    assert_select "li.timeline__entry .entry__amount--negative", text: /-€23\.50/
  end

  test "renders BankTransaction entry with matched pill" do
    sign_in_as(@user)
    get timeline_path

    assert_select ".entry__pill--matched",   text: "matched"
    assert_select ".entry__pill--unmatched", text: "unmatched"
  end

  test "brand link in shell points to timeline" do
    sign_in_as(@user)
    get timeline_path
    assert_select "a.shell__brand[href=?]", timeline_path
  end

  test "empty state shows capture link" do
    sign_in_as(@user)
    BankTransaction.delete_all
    Filing.delete_all

    get timeline_path
    assert_response :success
    assert_select ".timeline__empty a[href=?]", new_receipt_path, text: "Capture a receipt"
  end
end
