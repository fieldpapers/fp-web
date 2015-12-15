require 'test_helper'
require 'json'
require 'fakeweb'

module Api
  module V1
    class AtlasesControllerTest < ActionController::TestCase
      test "should get atlas index" do
        get :index, format: :json
        assert_response :success
      end

      test "get single atlas" do
        get :show, id: "1v00xegb", format: :json
        assert_response :success
        assert_match '"type":"FeatureCollection"', @response.body
      end

      # This isn't a very good test: since we don't have a task
      # manager running, we don't actually render the atlas here.
      test "create atlas" do
        FakeWeb.register_uri(:any, %r|#{Regexp.quote(FieldPapers::TASK_BASE_URL)}/.*|, body: "OK")

        data = { title: "", text: "",
                 paper_size: "letter", orientation: "landscape",
                 layout: "full-page", utm_grid: false, redcross_overlay: false,
                 zoom: 15,
                 provider: "http://{S}.tile.openstreetmap.org/{Z}/{X}/{Y}.png",
                 west:  11.358833312988281, south: 47.222599386628744,
                 east:  11.425437927246094, north: 47.25756309208489,
                 rows: 1, cols: 1 }
        post :create, atlas: data
        assert_response :success
      end

      # test "should get update" do
      #   get :update
      #   assert_response :success
      # end

      test "delete atlas" do
        delete :destroy, id: "3lwnzva3", format: :json
        assert_response :success
        get :show, id: "3lwnzva3", format: :json
        assert_response :not_found
      end
    end
  end
end
