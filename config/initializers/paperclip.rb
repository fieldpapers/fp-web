Paperclip::Attachment.default_options.merge!(
  # url:                  ':s3_domain_url',
  # path:                 ':class/:attachment/:id/:style/:filename',
  storage:              :s3,
  s3_credentials: {
    access_key_id:      Rails.application.secrets.aws["access_key_id"],
    secret_access_key:  Rails.application.secrets.aws["secret_access_key"],
    bucket:             Rails.application.secrets.aws["s3_bucket_name"]
  },
  s3_permissions:       :private,
  s3_protocol:          'https'
)
