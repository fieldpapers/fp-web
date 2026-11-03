creds = Aws::Credentials.new(
  FieldPapers::AWS_ACCESS_KEY_ID,
  FieldPapers::AWS_SECRET_ACCESS_KEY
)

Aws.config.update(
  region: FieldPapers::AWS_REGION,
  credentials: creds
)

Aws::Rails.add_action_mailer_delivery_method(
  :ses,
  credentials: creds,
  region: FieldPapers::AWS_REGION,
)