Paperclip::Attachment.default_options.merge!(
  storage: :filesystem,
  path: "#{FieldPapers::STATIC_PATH}:url",
)
