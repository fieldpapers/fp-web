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
      access_key_id:      FieldPapers::AWS_ACCESS_KEY_ID,
      secret_access_key:  FieldPapers::AWS_SECRET_ACCESS_KEY,
      bucket:             FieldPapers::S3_BUCKET_NAME
    },
    s3_region: FieldPapers::AWS_REGION,
    s3_permissions:       :private,
    s3_protocol:          'https'
  )
end
