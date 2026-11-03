require 'test_helper'

# The OSM login callback cases (see Users::OmniauthCallbacksController)
class OsmLoginTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
    OmniAuth.config.test_mode = true
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth.delete(:osm)
  end

  def osm_login(osm_id, name)
    OmniAuth.config.mock_auth[:osm] = OmniAuth::AuthHash.new(provider: "osm", uid: osm_id.to_s, info: { nickname: name })
    get "/users/auth/osm/callback"
  end

  def password_login(login)
    post user_session_path, params: { user: { login: login, password: "password123" } }
  end

  def signed_in_user
    get account_path
    controller.current_user if response.successful?
  end

  test "new OSM user gets an account right away" do
    osm_login(42, "Mapper")

    assert_redirected_to account_path
    user = User.find_by!(osm_id: 42)
    assert_equal "Mapper", user.username
    assert_nil user.email
    assert_equal user, signed_in_user
  end

  test "OSM login refreshes the username" do
    user = create_osm_user("Old Name", 42)

    osm_login(42, "New Name")

    assert_redirected_to root_path
    assert_equal user, signed_in_user
    assert_equal "New Name", user.reload.username
  end

  test "logging in again as the same OSM user" do
    user = create_osm_user("Mapper", 42)
    osm_login(42, "Mapper")

    osm_login(42, "Mapper")

    assert_redirected_to root_path
    assert_equal user, signed_in_user
  end

  test "switching OSM accounts signs in as the other account" do
    create_osm_user("A", 1)
    b = create_osm_user("B", 2)
    osm_login(1, "A")

    osm_login(2, "B")

    assert_equal b, signed_in_user
  end

  test "connecting OSM while logged in with a password moves the account to OSM" do
    legacy = create_user("legacy")
    legacy.update_column(:created_at, 10.years.ago)
    atlas = create_atlas(rows: 1, cols: 1, creator: legacy)
    atlas.update_column(:private, true)
    password_login("legacy")

    osm_login(42, "Mapper")

    assert_redirected_to account_path
    user = User.find_by!(osm_id: 42)
    assert_equal "Mapper", user.username
    assert_in_delta legacy.created_at, user.created_at, 1
    assert_equal user.id, Atlas.unscoped.find(atlas.id).user_id
    assert_not User.exists?(legacy.id)
    assert_equal user, signed_in_user
  end

  test "a connected account's old email can't be used to reset a password" do
    create_user("legacy")
    password_login("legacy")
    osm_login(42, "Mapper")
    delete destroy_user_session_path

    assert_no_emails do
      post user_password_path, params: { user: { email: "legacy@example.com" } }
    end
  end

  test "an OSM-connected account can't be connected to another OSM account" do
    a = create_osm_user("A", 1)
    osm_login(1, "A")

    osm_login(2, "B")

    assert_redirected_to account_path
    assert_nil User.find_by(osm_id: 2)
    assert_equal 1, a.reload.osm_id
    assert_equal a, signed_in_user
  end

  test "connecting a legacy account to an OSM account that already has one merges them" do
    osm_user = create_osm_user("Mapper", 42)
    legacy = create_user("legacy")
    atlas = create_atlas(rows: 1, cols: 1, creator: legacy)
    atlas.update_column(:private, true)
    create_snapshot(atlas, "A1", "snap0001", uploader: legacy)
    failed_atlas = create_atlas(rows: 1, cols: 1, creator: legacy)
    failed_atlas.update_column(:failed_at, Time.now)
    password_login("legacy")

    osm_login(42, "Mapper")

    assert_redirected_to account_path
    assert_not User.exists?(legacy.id)
    assert_equal osm_user.id, Atlas.unscoped.find(atlas.id).user_id
    assert_equal osm_user.id, Atlas.unscoped.find(failed_atlas.id).user_id
    assert_equal osm_user.id, Snapshot.unscoped.find_by!(slug: "snap0001").user_id
    assert_equal osm_user, signed_in_user
  end

  test "password login finds the legacy account when an OSM user has the same name" do
    create_osm_user("mapper", 42)
    legacy = create_user("mapper")

    password_login("mapper")

    assert_equal legacy, signed_in_user
  end

  test "OSM-connected accounts can't log in with a password" do
    user = create_user("legacy")
    user.update!(osm_id: 42)

    password_login("legacy")

    assert_nil signed_in_user
  end

  test "login page offers OSM and password login" do
    get new_user_session_path

    assert_response :success
    assert_select "form[action=?][method=post]", "/users/auth/osm"
    assert_select "form[action=?]", user_session_path
  end
end
