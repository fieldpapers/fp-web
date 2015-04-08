class ProcessSceneJob < ActiveJob::Base
  queue_as :default

  # bypass the default scope
  GlobalID::Locator.use :app do |gid|
    const_get(gid.model_name).unscoped.find(gid.model_id)
  end

  def perform(snapshot)
    pp snapshot

    s3 = AWS::S3.new

    bucket = Rails.application.secrets.aws["s3_bucket_name"]
    s3_upload_url_data = Snapshot::S3_UPLOAD_URL_FORMAT.match(snapshot.s3_scene_url)
    scene = s3.buckets[bucket].objects[s3_upload_url_data[:path]]

    begin
      tmp_scene = Tempfile.new(["snapshot", File.extname(snapshot.scene_file_name)], "tmp/")
      tmp_scene.binmode

      scene.read do |chunk|
        tmp_scene.write(chunk)
      end

      tmp_scene.close

      puts tmp_scene.path
    ensure
      # tmp_scene.unlink
    end
  end
end
