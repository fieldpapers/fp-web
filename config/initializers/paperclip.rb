case FieldPapers::PERSIST
when "local"
  Paperclip::Attachment.default_options.merge!(
    storage: :filesystem,
    path: "#{FieldPapers::STATIC_PATH}:url",
  )
when "s3"
  if Rails.application.secrets.aws["access_key_id"] && Rails.application.secrets.aws["secret_access_key"]
    Paperclip::Attachment.default_options.merge!(
      storage:              :s3,
      s3_credentials: {
        access_key_id:      Rails.application.secrets.aws["access_key_id"],
        secret_access_key:  Rails.application.secrets.aws["secret_access_key"],
        bucket:             Rails.application.secrets.aws["s3_bucket_name"]
      },
      s3_permissions:       :private,
      s3_protocol:          'https'
    )
  else
    Paperclip::Attachment.default_options.merge!(
      storage:              :s3,

      # If no AWS credentials were provided, assume we're running on EC2 with an
      # IAM role.
      s3_credentials: lambda { |a|
        prov = AWS::Core::CredentialProviders::EC2Provider.new

        return {
          bucket: Rails.application.secrets.aws["s3_bucket_name"],
          access_key_id: prov.credentials[:access_key_id],
          secret_access_key: prov.credentials[:secret_access_key]
        }
      },
      s3_permissions:       :private,
      s3_protocol:          'https'
    )
  end
end
