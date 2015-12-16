module Api
  module V1
    class S3UploadControllerTest < ActionController::TestCase
      test "new snapshot upload info" do
        begin
          get :show, filename: 'snap-1.png', format: :json
          assert_response :success
        rescue AWS::Errors::MissingCredentialsError
          skip "No AWS credentials"
        end
      end
    end
  end
end
