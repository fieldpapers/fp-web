require 'test_helper'
require 'json'
require 'fakeweb'

module Api
  module V1
    class SnapshotsControllerTest < ActionController::TestCase
      def s3_url(path)
        bucket = Rails.application.secrets.aws["s3_bucket_name"]
        region = Rails.application.secrets.aws["s3_bucket_region"] || 'us-east-1'
        s3 = region == 'us-east-1' ? 's3' : 's3-' + region
        "https://#{bucket}.#{s3}.amazonaws.com#{path}"
      end

      def setup
        bucket = Regexp.quote(Rails.application.secrets.aws["s3_bucket_name"])
        FakeWeb.register_uri(:any, %r|#{Regexp.quote(FieldPapers::TASK_BASE_URL)}/.*|, body: "OK")
        FakeWeb.register_uri(:any, %r|https://#{bucket}\.s3.*\.amazonaws\.com/uploads/.*|, body: "OK")
      end

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
        scene_url = s3_url("/uploads/L_D1_XpVixCgHixHVP4RYg/snap-1.png")
        post :create, s3_scene_url: scene_url
        assert_response :success
      end

      test "delete snapshot" do
        begin
          delete :destroy, id: "5nuv8bki", format: :json
          assert_response :success
          get :show, id: "5nuv8bki", format: :json
          assert_response :not_found
        rescue AWS::Errors::MissingCredentialsError
          skip "No AWS credentials"
        end
      end
    end
  end
end
