require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "requires login" do
    get :show

    assert_redirected_to new_user_session_path
  end

  test "shows the account page" do
    sign_in create_user("mapper")

    get :show

    assert_response :success
    assert_select "p", text: /Logged in as mapper \(mapper@example.com\)/
    assert_select "p", text: "You haven't made any atlases or uploaded any snapshots yet."
  end

  test "summarizes the user's content, including private and failed atlases" do
    user = create_user("mapper")
    create_atlas(rows: 1, cols: 1, creator: user)
    create_atlas(rows: 1, cols: 1, creator: user).update_column(:private, true)
    create_atlas(rows: 1, cols: 1, creator: user).update_column(:failed_at, Time.now)
    create_atlas(rows: 1, cols: 1, creator: create_user("other"))
    create_pending_snapshot("snappnd1").update_column(:user_id, user.id)
    sign_in user

    get :show

    assert_select "p", text: /You have 3 atlases and 1 snapshot\./
  end

  test "deleting the account" do
    user = create_user("mapper")
    sign_in user

    delete :destroy

    assert_redirected_to root_path
    assert_not User.exists?(user.id)
  end
end
