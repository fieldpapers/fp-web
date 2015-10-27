# To upload images for new snapshots via the API, we use pre-signed S3
# URLs -- this is a simpler approach for API users since it removes
# the need to deal with any AWS authorisation issues: the client just
# does a PUT to the provided upload URL with the right Content-Type
# and things just work.  The client then passes the public URL of the
# uploaded S3 object in the API call to create a new snapshot.  (This
# feels like a bit of a bodge, but it's pretty much equivalent to the
# approach used for browser-based uploads.)

module Api
  module V1
    class S3UploadController < ApplicationController
      respond_to :json
      skip_before_filter :verify_authenticity_token

      def show
        bucket = Rails.application.secrets.aws["s3_bucket_name"]
        region = Rails.application.secrets.aws["s3_bucket_region"]
        filename = params[:filename] + (params[:format] ? ('.' + params[:format]) : '')

        s3 = AWS::S3.new(region: region)
        key = "uploads/" + SecureRandom.urlsafe_base64 + "/" + filename
        obj = s3.buckets[bucket].objects[key]
        content_type = "image/" + filename.split('.')[-1]
        upload_url = obj.url_for(:write, :content_type => content_type).to_s

        render json: { bucket: bucket, region: region, key: key,
                       public_url: obj.public_url.to_s,
                       upload_url: upload_url, upload_content_type: content_type }
      end
    end
  end
end
