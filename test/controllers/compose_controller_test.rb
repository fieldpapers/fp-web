require 'test_helper'

class ComposeControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper
  include Devise::Test::ControllerHelpers

  test "create enqueues rendering" do
    post :create, params: {
      atlas: {
        west: -122.3, south: 37.7, east: -122.2, north: 37.8, zoom: 14, rows: 1, cols: 2,
        provider: "https://tile.openstreetmap.org/{Z}/{X}/{Y}.png",
        orientation: "landscape", paper_size: "letter", layout: "full-page",
      }
    }

    atlas = Atlas.unscoped.last
    assert_redirected_to atlas_path(atlas)
    assert_enqueued_with(job: RenderAtlasJob, args: [atlas.id])
  end

  test "create rejects atlases with too many pages" do
    assert_no_difference -> { Atlas.unscoped.count } do
      post :create, params: {
        atlas: {
          west: -122.3, south: 37.7, east: -122.2, north: 37.8, zoom: 14, rows: 11, cols: 10,
          provider: "https://tile.openstreetmap.org/{Z}/{X}/{Y}.png",
          orientation: "landscape", paper_size: "letter", layout: "full-page",
        }
      }
    end

    assert_redirected_to compose_path
    assert_equal "An atlas can have at most 100 pages", flash[:alert]
    assert_no_enqueued_jobs
  end
end
