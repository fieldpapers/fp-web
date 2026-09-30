require 'test_helper'

class SnapshotsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  def get_csv(atlas)
    get :index, params: { atlas_id: atlas.slug }, format: :csv
  end

  def url(slug)
    @controller.snapshot_url(slug)
  end

  def capture_sql(&block)
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  end

  test "csv for a single-page atlas (no index page)" do
    atlas = create_atlas(rows: 1, cols: 1)
    create_snapshot(atlas, "A1", "snap0001")

    get_csv(atlas)

    assert_response :success
    assert_equal ",A\n1,\"#{url("snap0001")}\"\n", response.body
  end

  test "csv grid for a multi-page atlas" do
    atlas = create_atlas(rows: 3, cols: 2)
    create_snapshot(atlas, "i", "snapidx1")
    create_snapshot(atlas, "B1", "snapold1", created_at: 2.days.ago)
    create_snapshot(atlas, "B1", "snapnew1", created_at: 1.day.ago)
    create_snapshot(atlas, "A2", "snapa2aa")

    get_csv(atlas)

    assert_response :success
    assert_equal [
      "\"#{url("snapidx1")}\",A,B,C",
      "1,\"\",\"#{url("snapnew1")},#{url("snapold1")}\",\"\"",
      "2,\"#{url("snapa2aa")}\",\"\",\"\"",
    ].join("\n") + "\n", response.body
  end

  test "csv query count does not grow with grid size" do
    small = create_atlas(rows: 1, cols: 2)
    large = create_atlas(rows: 5, cols: 5)

    assert_equal capture_sql { get_csv(small) }.size, capture_sql { get_csv(large) }.size
  end

  test "csv does not count all snapshots" do
    atlas = create_atlas(rows: 1, cols: 1)

    queries = capture_sql { get_csv(atlas) }

    assert_empty queries.grep(/COUNT/i)
  end

  test "html index" do
    atlas = create_atlas(rows: 1, cols: 1)
    create_snapshot(atlas, "A1", "snap0001")

    get :index

    assert_response :success
    assert_includes response.body, "static-map-snap0001"
  end
end
