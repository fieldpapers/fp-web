require "open3"
require "raven"
require "timeout"

class ProcessSceneJob < ActiveJob::Base
  queue_as :default

  BUCKET = Rails.application.secrets.aws["s3_bucket_name"]
  STEP_COUNT = 5 # started, QR code, process, get extent, upload

  # bypass the default scope
  GlobalID::Locator.use :app do |gid|
    const_get(gid.model_name).unscoped.find(gid.model_id)
  end

  rescue_from(Exception) do |exception|
    logger.warn exception
    Raven.capture_exception(exception)
  end

  def perform(snapshot)
    update_progress(snapshot)

    begin
      # TODO consider attaching $TMPDIR as a volume when using `docker run`
      image = download_image(snapshot)

      # NOTE: the use of URLs theoretically means that atlases and scans are
      # portable between instances, but the reality is somewhat different
      url = get_url(snapshot, image)

      uri = URI.parse(URI.decode(url))
      (atlas_slug, page_number) = if uri.query
        CGI.parse(uri.query)["id"][0].split("/")
      else
        uri.path.split("/").slice(-2, 2)
      end

      page = Atlas.unscoped.friendly.find(atlas_slug).pages.find_by_page_number(page_number)

      snapshot.update \
        page: page,
        private: page.atlas.private,
        print_href: url

      geotiff = process(snapshot, image)

      extent = transform(get_extent(snapshot, geotiff))

      geotiff_url = upload(snapshot, geotiff)

      snapshot.update \
        progress: 1,
        west: extent[0][0],
        south: extent[0][1],
        east: extent[1][0],
        north: extent[1][1],
        zoom: page.zoom,
        base_url: "https://s3.amazonaws.com/#{BUCKET}/snapshots/#{snapshot.slug}",
        geotiff_url: geotiff_url,
        has_geotiff: "yes", # TODO turn this into a boolean field
        decoded_at: Time.now
    rescue Exception => e
      snapshot.update \
        failed_at: Time.now

      raise
    ensure
    end
  end

  private

  def download_image(snapshot)
    s3 = AWS::S3.new

    bucket = Rails.application.secrets.aws["s3_bucket_name"]
    s3_upload_url_data = Snapshot::S3_UPLOAD_URL_FORMAT.match(snapshot.s3_scene_url)
    s3.buckets[bucket].objects[s3_upload_url_data[:path]].read
  end

  def get_extent(snapshot, image)
    cmd = %w(docker run --rm -i fieldpapers/paper gdalinfo /vsistdin/)

    out = ""
    err = ""
    stdin, stdout, stderr, t = Open3.popen3(*cmd)

    begin
      Timeout.timeout(30) do
        stdin.binmode
        stdin.write image
        stdin.close

        while true
          begin
            out << stdout.read_nonblock(1024)
            err << stderr.read_nonblock(1024)
          rescue IO::WaitReadable
            IO.select([stdout, stderr])
            retry
          rescue IO::WaitWritable
            IO.select(nil, [stdout, stderr])
            retry
          rescue EOFError
            break if stdout.eof? && stderr.eof?
          end
        end

        # wait for the process to finish
        status = t.value

        raise "Failed to determine extent for snapshot #{snapshot.slug}\nstdout: #{out}\nstderr: #{err}" unless status.success?

        update_progress(snapshot)

        return out.lines.select do |x|
            x =~ /(Lower Left|Upper Right)/
          end.map(&:strip).map do |x|
            x.gsub(/[^\(]*\((.+)\).+/, "\\1")
          end.map do |x|
            x.split(", ")
          end.map do |x|
            x.map(&:to_f)
          end
      end
    rescue Timeout::Error
      Process.kill 9, t.pid

      raise "Timed out determining extent for snapshot #{snapshot.slug}"
    ensure
      stdin.close unless stdin.closed?
      stdout.close
      stderr.close
    end
  end

  def get_url(snapshot, image)
    # zbar uses ImageMagick internally, so :- is stdin
    cmd = %w(docker run --rm -i fieldpapers/paper zbarimg --raw -q :-)

    out = ""
    err = ""
    stdin, stdout, stderr, t = Open3.popen3(*cmd)

    begin
      Timeout.timeout(30) do
        stdin.binmode
        stdin.write image
        stdin.close

        while true
          begin
            out << stdout.read_nonblock(1024)
            err << stderr.read_nonblock(1024)
          rescue IO::WaitReadable
            IO.select([stdout, stderr])
            retry
          rescue IO::WaitWritable
            IO.select(nil, [stdout, stderr])
            retry
          rescue EOFError
            break if stdout.eof? && stderr.eof?
          end
        end

        # wait for the process to finish
        status = t.value

        raise "Failed to read QR code for snapshot #{snapshot.slug}\nstdout: #{out}\nstderr: #{err}" unless status.success?

        update_progress(snapshot)

        return URI.decode(out.strip)
      end
    rescue Timeout::Error
      Process.kill 9, t.pid

      raise "Timed out reading QR code for snapshot #{snapshot.slug}"
    ensure
      stdin.close unless stdin.closed?
      stdout.close
      stderr.close
    end
  end

  def partial_progress(snapshot)
    1.0 / STEP_COUNT
  end

  def process(snapshot, image)
    cmd = [
      "docker",
      "run",
      "--rm",
      "-i",
      "-e", "SENTRY_DSN=#{ENV["SENTRY_DSN"]}",
      "fieldpapers/paper",
      "process_snapshot.py",
    ]

    out = ""
    err = ""
    stdin, stdout, stderr, t = Open3.popen3(*cmd)

    begin
      Timeout.timeout(120) do
        stdin.binmode
        stdin.write image
        stdin.close

        while true
          begin
            out << stdout.read_nonblock(1024)
            err << stderr.read_nonblock(1024)
          rescue IO::WaitReadable
            IO.select([stdout, stderr])
            retry
          rescue IO::WaitWritable
            IO.select(nil, [stdout, stderr])
            retry
          rescue EOFError
            break if stdout.eof? && stderr.eof?
          end
        end

        # wait for the process to finish
        status = t.value

        raise "Failed to process snapshot #{snapshot.slug}\nstdout: #{out}\nstderr: #{err}" unless status.success?

        update_progress(snapshot)

        return out
      end
    rescue Timeout::Error
      Process.kill 9, t.pid

      raise "Timed out processing snapshot #{snapshot.slug}"
    ensure
      stdin.close unless stdin.closed?
      stdout.close
      stderr.close
    end
  end

  def transform(coords)
    coords = coords.map do |x|
      x.join(" ")
    end.join("\n")

    cmd = %w(docker run --rm -i fieldpapers/paper gdaltransform -s_srs EPSG:3857 -t_srs EPSG:4326)

    out = ""
    err = ""
    stdin, stdout, stderr, t = Open3.popen3(*cmd)

    begin
      Timeout.timeout(30) do
        stdin.write(coords)
        stdin.close

        while true
          begin
            out << stdout.read_nonblock(1024)
            err << stderr.read_nonblock(1024)
          rescue IO::WaitReadable
            IO.select([stdout, stderr])
            retry
          rescue IO::WaitWritable
            IO.select(nil, [stdout, stderr])
            retry
          rescue EOFError
            break if stdout.eof? && stderr.eof?
          end
        end

        # wait for the process to finish
        status = t.value

        raise "Failed to transform coordinates: #{coords}\nstdout: #{out}\nstderr: #{err}" unless status.success?

        return out.lines.map(&:strip).map do |x|
          x.split(" ")[0..1]
          end.map do |x|
            x.map(&:to_f)
          end
      end
    rescue Timeout::Error
      Process.kill 9, t.pid

      raise "Timed out transforming coordinates: #{coords}"
    ensure
      stdin.close unless stdin.closed?
      stdout.close
      stderr.close
    end
  end

  def update_progress(snapshot, increments = 1)
    snapshot.update(progress: snapshot.progress + (increments * partial_progress(snapshot)))
  end

  def upload(snapshot, image)
    s3 = AWS::S3.new

    # TODO stop relying on conventions
    # key = "snapshots/#{snapshot.slug}/snapshot-#{snapshot.slug}.tiff"
    key = "snapshots/#{snapshot.slug}/walking-paper-#{snapshot.slug}.tif"
    bucket = Rails.application.secrets.aws["s3_bucket_name"]

    logger.debug "Uploading to #{bucket}/#{key} for snapshot #{snapshot.slug}"

    s3.buckets[bucket].objects[key].write \
      image,
      content_length: image.length,
      acl: :public_read,
      cache_control: "public,max-age=31536000",
      content_type: "image/tiff"

    update_progress(snapshot)

    "https://s3.amazonaws.com/#{bucket}/#{key}"
  end
end
