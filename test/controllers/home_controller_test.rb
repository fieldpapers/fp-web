require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def urls
    Rails.application.routes.url_helpers
  end

  test "logged out index is the landing page" do
    get :index

    assert_response :success
    assert_select "h2", text: "Welcome to Field Papers"
    assert_select ".cards"
  end

  test "dashboard with nothing yet shows the onboarding cards" do
    sign_in create_user("mapper")

    get :index

    assert_response :success
    assert_select "h2", text: "Welcome, mapper"
    assert_select ".cards"
    assert_select ".new-card", 0
  end

  test "dashboard shows own private and failed items, not others'" do
    user = create_user("mapper")
    other = create_user("other")

    public_atlas = create_atlas(rows: 1, cols: 2, creator: user)
    private_atlas = create_atlas(rows: 1, cols: 2, creator: user)
    private_atlas.update_column(:private, true)
    failed_atlas = create_atlas(rows: 1, cols: 1, creator: user)
    failed_atlas.update_column(:failed_at, Time.now)
    others_atlas = create_atlas(rows: 1, cols: 1, creator: other)

    create_snapshot(private_atlas, "A1", "snapprv1", uploader: user)
    create_pending_snapshot("snappnd1").update_column(:user_id, user.id)
    create_snapshot(public_atlas, "A1", "snapothr", uploader: other)

    sign_in user
    get :index

    assert_response :success
    assert_select ".cards", 0
    assert_select ".new-card a[href=?]", urls.compose_path
    assert_select ".new-card a[href=?]", urls.new_snapshot_path
    [public_atlas, private_atlas, failed_atlas].each do |atlas|
      assert_select ".map-card-title[href=?]", urls.atlas_path(atlas)
    end
    assert_select ".map-card-title[href=?]", urls.atlas_path(others_atlas), 0

    assert_select ".map-card-title[href=?]", urls.snapshot_path("snapprv1"), text: "Page A1 of Untitled"
    assert_select ".map-card-title[href=?]", urls.snapshot_path("snappnd1"), text: "Unprocessed snapshot"
    assert_select ".map-card-title[href=?]", urls.snapshot_path("snapothr"), 0
  end
end
