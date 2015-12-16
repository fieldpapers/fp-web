S3DirectUpload.config do |c|
  if Rails.application.secrets.aws["access_key_id"] && Rails.application.secrets.aws["secret_access_key"]
    # if AWS credentials are available, use them

    c.access_key_id     = Rails.application.secrets.aws["access_key_id"]
    c.secret_access_key = Rails.application.secrets.aws["secret_access_key"]
  else
    # if AWS credentials are _not_ available, assume we're on EC2 with an IAM role
    prov = AWS::Core::CredentialProviders::EC2Provider.new

    c.access_key_id     = lambda { prov.credentials[:access_key_id] }
    c.secret_access_key = lambda { prov.credentials[:secret_access_key] }
    c.session_token = lambda { prov.credentials[:session_token] }
  end

  c.bucket = Rails.application.secrets.aws["s3_bucket_name"]
  c.region = Rails.application.secrets.aws["s3_bucket_region"]
end
