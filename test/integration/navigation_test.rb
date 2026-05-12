require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  setup { @user = users(:luis) }

  test "signed-in root redirects to home" do
    sign_in_as(@user)
    get root_path
    assert_redirected_to home_path
  end

  test "public root shows landing without shell" do
    get root_path
    assert_response :success
    assert_select "header.shell__header", false, "Shell header should not appear on public landing"
    assert_select "nav.bottom-nav",       false, "Bottom nav should not appear on public landing"
    assert_select "h1.brand", text: "brain"
  end

  test "authenticated pages render the shell" do
    sign_in_as(@user)
    get new_receipt_path

    assert_response :success
    assert_select "header.shell__header"
    assert_select "nav.shell__nav"
    assert_select "nav.bottom-nav"
    assert_select "header.shell__header a.shell__brand", text: "brain"
    assert_select "header.shell__header a", text: "Home"
    assert_select "header.shell__header a", text: "Capture"
    assert_select "header.shell__header a", text: "Invoices"
    assert_select "form[action=?][method=?]", session_path, "post" do
      assert_select "input[name='_method'][value='delete']"
      assert_select "button.shell__signout", text: "Sign out"
    end
  end

  test "invoices index renders inside shell" do
    sign_in_as(@user)
    get invoices_path
    assert_response :success
    assert_select "header.shell__header"
    assert_select "h1", text: "Invoices"
  end

  test "home page renders stream and tray" do
    sign_in_as(@user)
    get home_path
    assert_response :success
    assert_select "header.shell__header"
    assert_select "section.stream"
    assert_select "aside.tray"
  end

  test "sign out clears session and returns to public root" do
    sign_in_as(@user)
    delete session_path
    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "unauthenticated access to invoices redirects to sign in" do
    get invoices_path
    assert_redirected_to new_session_path
  end

  test "unauthenticated access to home redirects to sign in" do
    get home_path
    assert_redirected_to new_session_path
  end
end
