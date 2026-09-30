require 'test_helper'

class AtlasesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def urls
    Rails.application.routes.url_helpers
  end

  test "index shows page counts" do
    create_atlas(rows: 1, cols: 1)
    create_atlas(rows: 2, cols: 3)

    get :index

    assert_response :success
    assert_includes response.body, "1 page"
    assert_includes response.body, "7 pages"
  end

  test "index query count does not grow with number of atlases" do
    create_atlas(rows: 1, cols: 1, creator: create_user("mapper"))
    few = capture_sql { get :index }

    3.times { |i| create_atlas(rows: 2, cols: 2, creator: create_user("mapper#{i}")) }
    many = capture_sql { get :index }

    assert_equal few.size, many.size
  end

  test "geojson with creator and snapshot uploader" do
    user = create_user("mapper")
    atlas = create_atlas(rows: 1, cols: 2, creator: user)
    create_snapshot(atlas, "A2", "snap0001", uploader: user)

    get :show, params: { id: atlas.slug }, format: :geojson

    assert_response :success
    features = JSON.parse(response.body)["features"]

    atlas_props = features.find { |f| f["properties"]["type"] == "atlas" }["properties"]
    assert_equal urls.atlases_url(username: "mapper"), atlas_props["url_user"]

    snapshot_props = features.find { |f| f["properties"]["type"] == "snapshot" }["properties"]
    assert_equal urls.snapshots_url(username: "mapper"), snapshot_props["url_uploader"]
    assert_equal urls.atlas_page_atlas_url(atlas, "A2"), snapshot_props["url_page"]
  end

  test "geojson for anonymous atlas" do
    atlas = create_atlas(rows: 1, cols: 1)

    get :show, params: { id: atlas.slug }, format: :geojson

    assert_response :success
    atlas_props = JSON.parse(response.body)["features"].first["properties"]
    assert_nil atlas_props["url_user"]
  end
end
