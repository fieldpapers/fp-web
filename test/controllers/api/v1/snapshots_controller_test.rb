require 'test_helper'
require 'json'
require 'fakeweb'

module Api
  module V1
    class SnapshotsControllerTest < ActionController::TestCase
      test "should get snapshot index" do
        get :index, format: :json
        assert_response :success
      end

      test "get single snapshot" do
        get :show, id: "77btuvr8", format: :json
        assert_response :success
        assert_match '"type":"FeatureCollection"', @response.body
      end

      test "create snapshot" do
        bucket = Regexp.quote(Rails.application.secrets.aws["s3_bucket_name"])
        FakeWeb.register_uri(:any, %r|#{Regexp.quote(FieldPapers::TASK_BASE_URL)}/.*|, body: "OK")
        FakeWeb.register_uri(:any, %r|https://#{bucket}\.s3.*\.amazonaws\.com/uploads/.*|, body: "OK")

        scene_url = 'https://fieldpapers-dev.s3-us-west-2.amazonaws.com/' +
                    'uploads/L_D1_XpVixCgHixHVP4RYg/snap-1.png'
        post :create, s3_scene_url: scene_url
        assert_response :success
      end

      test "delete snapshot" do
        delete :destroy, id: "5nuv8bki", format: :json
        assert_response :success
        get :show, id: "5nuv8bki", format: :json
        assert_response :not_found
      end
    end
  end
end
