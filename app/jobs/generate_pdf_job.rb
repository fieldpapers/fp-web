require "open3"
require "raven"
require "timeout"

class GeneratePdfJob < ActiveJob::Base
  queue_as :default

  ADDITIONAL_STEP_COUNT = 3 # started, merge pages, upload

  # bypass the default scope
  GlobalID::Locator.use :app do |gid|
    const_get(gid.model_name).unscoped.find(gid.model_id)
  end

  rescue_from(Exception) do |exception|
    logger.warn exception
    logger.warn exception.backtrace.join("\n")
    Raven.capture_exception(exception)
  end

  def perform(atlas)
    update_progress(atlas)

    files = []
    file = nil

    begin
      files = atlas.pages.map(&method(:render_page))

      file = merge_pages(atlas, files.map(&:path)) if atlas.pages.size > 1
      file ||= files.first

      s3 = AWS::S3.new

      # upload file to S3

      key = "prints/#{atlas.slug}/atlas-#{atlas.slug}.pdf"
      bucket = Rails.application.secrets.aws["s3_bucket_name"]

      logger.debug "Uploading #{file.path} to #{bucket}/#{key} for atlas #{atlas.slug}"

      s3.buckets[bucket].objects[key].write \
        file: file.path,
        acl: :public_read,
        cache_control: "public,max-age=31536000",
        content_type: "application/pdf"

      # attach file to Atlas
      atlas.update \
        pdf_url: "https://s3.amazonaws.com/#{bucket}/#{key}",
        progress: 1,
        composed_at: Time.now
    rescue
      atlas.update \
        failed_at: Time.now

      raise
    ensure
      # clean up our temp files
      File.delete(*files.map(&:path))

      # possibly a merged file
      File.unlink(file.path) if file && File.file?(file.path)
    end
  end

  private

  def merge_pages(atlas, filenames)
    cmd = %w(gs -q -sDEVICE=pdfwrite -o -)

    cmd.concat(filenames)

    logger.debug "Merging pages using '#{cmd}'"

    pid = nil
    output = Tempfile.new(["atlas", ".pdf"], "tmp/")

    begin
      Timeout.timeout(30) do
        pid = IO.popen(cmd) do |out|
          IO.copy_stream(out, output)
        end
      end
    rescue Timeout::Error
      Process.kill 9, t.pid

      raise "Timed out waiting to merge pages #{filenames.join(",")} for #{atlas.slug}"
    end

    unless $?.success?
      raise "Failed to merge pages"
    end

    logger.debug "Merged output: #{output.path}"

    update_progress(atlas)

    output
  end

  def render_page(page)
    logger.debug "Rendering #{page.atlas.slug}/#{page.page_number}"
    cmd = [
      "docker",
      "run",
      "--rm",
      "-e", "API_BASE_URL=#{ENV["API_BASE_URL"] || "http://fieldpapers.org/"}",
      "-e", "SENTRY_DSN=#{ENV["SENTRY_DSN"]}",
      "fieldpapers/paper",
    ]

    case page.page_number
    when "i"
      cmd << "create_index.py"
      cmd << "-s" << page.atlas.paper_size
      cmd << "-l" << page.atlas.layout
      cmd << "-o" << page.atlas.orientation
      cmd << "-b" << page.north << page.west << page.south << page.east
      cmd << "-e" << page.atlas.north << page.atlas.west << page.atlas.south << page.atlas.east
      cmd << "-z" << page.zoom
      cmd << "-p" << page.provider.gsub(/{s}\./i, "")
      cmd << "-c" << page.atlas.cols
      cmd << "-r" << page.atlas.rows
      cmd << page.atlas.slug
    else
      cmd << "create_page.py"
      cmd << "-s" << page.atlas.paper_size
      cmd << "-l" << page.atlas.layout
      cmd << "-o" << page.atlas.orientation
      cmd << "-b" << page.north << page.west << page.south << page.east
      cmd << "-n" << page.page_number
      cmd << "-z" << page.zoom
      cmd << "-p" << page.provider.gsub(/{s}\./i, "")
      cmd << page.atlas.slug
    end

    # convert all arguments to strings
    cmd = cmd.map(&:to_s)

    logger.debug cmd.join(" ")

    output = Tempfile.new(["page", ".pdf"], "tmp/")
    output.binmode

    out = ""
    err = ""
    stdin, stdout, stderr, t = Open3.popen3(*cmd)

    begin
      Timeout.timeout(30) do
        stdin.close

        while t.status
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

        out << stdout.read
        err << stderr.read

        # wait for the process to finish
        status = t.value

        raise "Failed to render page #{page.page_number}\nstdout: #{out}\nstderr: #{err}" unless status.success?

        output.write(out)
      end
    rescue Timeout::Error
      Process.kill 9, t.pid

      raise "Timed out waiting to render page #{page.page_number} for #{page.atlas.slug}\nstdout: #{out}\nstderr: #{err}"
    ensure
      stdin.close unless stdin.closed?
      stdout.close
      stderr.close
    end

    logger.debug "#{page.atlas.slug}/#{page.page_number} rendered to #{output.path}"

    page.update(composed_at: Time.now)
    update_progress(page.atlas)

    output
  end

  def update_progress(atlas, increments = 1)
    atlas.update(progress: atlas.progress + (increments * partial_progress(atlas)))
  end

  private

  def partial_progress(atlas)
    1.0 / ((atlas.pages.size || 0) + ADDITIONAL_STEP_COUNT)
  end
end
