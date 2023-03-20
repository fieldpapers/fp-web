require 'aws-sdk-core'

Aws.config.update(
  region: Rails.application.secrets[:aws][:s3_bucket_region],
  credentials: Aws::Credentials.new(
    Rails.application.secrets[:aws][:access_key_id],
    Rails.application.secrets[:aws][:secret_access_key]
  )
)