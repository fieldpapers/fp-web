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

  test "legacy accounts are offered to connect to OSM, not to merge" do
    sign_in create_user("mapper")

    get :show

    assert_select "form[action=?]", "/users/auth/osm"
    assert_select "form[action=?]", "/account/merge", 0
  end

  test "OSM accounts are offered to merge, not to connect" do
    sign_in create_osm_user("Mapper", 42)

    get :show

    assert_select "p", text: /Logged in as Mapper with OpenStreetMap/
    assert_select "form[action=?]", "/users/auth/osm", 0
    assert_select "form[action=?]", "/account/merge"
  end

  test "merging a legacy account, including private and failed atlases" do
    user = create_osm_user("Mapper", 42)
    legacy = create_user("legacy")
    atlas = create_atlas(rows: 1, cols: 1, creator: legacy)
    atlas.update_column(:private, true)
    failed_atlas = create_atlas(rows: 1, cols: 1, creator: legacy)
    failed_atlas.update_column(:failed_at, Time.now)
    create_snapshot(atlas, "A1", "snap0001", uploader: legacy)
    sign_in user

    post :merge, params: { login: "legacy@example.com", password: "password123" }

    assert_redirected_to account_path
    assert_not User.exists?(legacy.id)
    assert_equal [user.id], Atlas.unscoped.where(id: [atlas, failed_atlas]).pluck(:user_id).uniq
    assert_equal user.id, Snapshot.unscoped.find_by!(slug: "snap0001").user_id
  end

  test "merging a legacy account with an unsalted SHA1 password" do
    user = create_osm_user("Mapper", 42)
    legacy = create_user("legacy")
    legacy.update_columns(encrypted_password: "", legacy_password: Digest::SHA1.hexdigest("oldpassword"))
    sign_in user

    post :merge, params: { login: "legacy", password: "oldpassword" }

    assert_not User.exists?(legacy.id)
  end

  test "merging requires the right password" do
    user = create_osm_user("Mapper", 42)
    legacy = create_user("legacy")
    sign_in user

    post :merge, params: { login: "legacy", password: "wrong" }

    assert_equal "Wrong username or password.", flash[:alert]
    assert User.exists?(legacy.id)
  end

  test "OSM-connected accounts can't be merged" do
    user = create_osm_user("Mapper", 42)
    other = create_user("other")
    other.update!(osm_id: 43)
    sign_in user

    post :merge, params: { login: "other", password: "password123" }

    assert User.exists?(other.id)
  end

  test "legacy accounts can't merge other accounts" do
    user = create_user("mapper")
    other = create_user("other")
    sign_in user

    post :merge, params: { login: "other", password: "password123" }

    assert User.exists?(other.id)
  end
end
