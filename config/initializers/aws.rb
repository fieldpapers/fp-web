creds = Aws::Credentials.new(
  Rails.application.secrets[:aws][:access_key_id],
  Rails.application.secrets[:aws][:secret_access_key]
)

Aws.config.update(
  region: Rails.application.secrets[:aws][:s3_bucket_region],
  credentials: creds
)

Aws::Rails.add_action_mailer_delivery_method(
  :ses,
  credentials: creds,
  region: Rails.application.secrets[:aws][:s3_bucket_region],
)