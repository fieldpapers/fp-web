require 'test_helper'

class PagesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test "show doesn't find atlases by numeric id" do
    atlas = create_atlas(rows: 1, cols: 1)

    assert_raises(ActiveRecord::RecordNotFound) { get :show, params: { id: atlas.id.to_s, page_number: "A1" } }
  end
end
