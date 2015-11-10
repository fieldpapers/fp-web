if Rails.env.production?
  Paperclip::Attachment.default_options.merge!(
    # url:                  ':s3_domain_url',
    # path:                 ':class/:attachment/:id/:style/:filename',
    storage:              :s3,
    # Here, "production" is a custom deployment on Amazon Web
    # Services, and we use temporary AWS credentials associated with
    # the EC2 instance where we are running.  (See top-level README
    # for more details.)
    s3_credentials: lambda { |a|
      prov = AWS::Core::CredentialProviders::EC2Provider.new
      { bucket: Rails.application.secrets.aws["s3_bucket_name"],
        access_key_id: prov.credentials[:access_key_id],
        secret_access_key: prov.credentials[:secret_access_key] }
    },
    s3_permissions:       :private,
    s3_protocol:          'https'
  )
else
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
end
