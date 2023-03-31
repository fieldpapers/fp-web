case FieldPapers::PERSIST
when "local"
  Paperclip::Attachment.default_options.merge!(
    storage: :filesystem,
    path: "#{FieldPapers::STATIC_PATH}:url",
  )
when "s3"
  Paperclip::Attachment.default_options.merge!(
    storage:              :s3,
    s3_credentials: {
      access_key_id:      Rails.application.secrets[:aws][:access_key_id],
      secret_access_key:  Rails.application.secrets[:aws][:secret_access_key],
      bucket:             Rails.application.secrets[:aws][:s3_bucket_name]
    },
    s3_region: Rails.application.secrets[:aws][:s3_bucket_region],
    s3_permissions:       :private,
    s3_protocol:          'https'
  )
end
