module Api
  module V1
    class S3UploadControllerTest < ActionController::TestCase
      test "new snapshot upload info" do
        get :show, filename: 'snap-1.png', format: :json
        assert_response :success
      end
    end
  end
end
