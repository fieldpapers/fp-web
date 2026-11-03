S3DirectUpload.config do |c|
  c.access_key_id     = FieldPapers::AWS_ACCESS_KEY_ID
  c.secret_access_key = FieldPapers::AWS_SECRET_ACCESS_KEY
  c.bucket = FieldPapers::S3_BUCKET_NAME
  c.region = FieldPapers::AWS_REGION
  c.url = "https://s3.#{c.region}.amazonaws.com/#{c.bucket}/"
end
