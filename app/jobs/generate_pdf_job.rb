require "timeout"

class GeneratePdfJob < ActiveJob::Base
  queue_as :default

  def perform(atlas)
    filenames = atlas.pages.map(&method(:render_page))

    filename = merge_pages(filenames) if atlas.pages.size > 1
    filename ||= filenames.first

    s3 = AWS::S3.new

    # upload file to S3

    key = "prints/#{atlas.slug}/atlas-#{atlas.slug}.pdf"
    bucket = Rails.application.secrets.aws["s3_bucket_name"]
    s3.buckets[bucket].objects[key].write \
      file: filename,
      acl: :public_read,
      cache_control: "public,max-age=31536000",
      content_type: "application/pdf"

    # attach file to Atlas
    atlas.update(pdf_url: "https://s3.amazonaws.com/#{bucket}/#{key}")
  end

  private

  def merge_pages(filenames)
    gs = %w(gs -q -sDEVICE=pdfwrite -o -)

    gs.concat(filenames)

    pdf = IO.popen(gs)

    (pid, status) = Process.wait2(pdf.pid)

    unless status.success?
      raise "Failed to merge pages"
    end

    atlas = Tempfile.new(["atlas", ".pdf"], "tmp/")

    IO.copy_stream(pdf, atlas)

    atlas.path
  end

  def render_page(page)
    cmd = %w(docker run fieldpapers/paper)

    case page.page_number
    when "i"
      cmd << "create_index.py"
      cmd << "-s" << page.atlas.paper_size
      cmd << "-l" << page.atlas.layout
      cmd << "-o" << page.atlas.orientation
      cmd << "-b" << page.north << page.west << page.south << page.east
      cmd << "-e" << page.atlas.north << page.atlas.west << page.atlas.south << page.atlas.east
      cmd << "-z" << page.zoom
      cmd << "-p" << page.provider
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
      cmd << "-p" << page.provider
      cmd << page.atlas.slug
    end

    # convert all arguments to strings
    cmd = cmd.map(&:to_s)

    pipe, status = nil

    begin
      Timeout.timeout(30) do
        pipe = IO.popen(cmd)

        (pid, status) = Process.wait2(pipe.pid)
      end
    rescue Timeout::Error
      Process.kill 9, pipe.pid
      Process.wait pipe.pid

      raise "Timed out waiting to render page #{page.page_number}"
    end

    unless status.success?
      raise "Failed to render page #{page.page_number}"
    end

    output = Tempfile.new(["page", ".pdf"], "tmp/")

    IO.copy_stream(pipe, output)

    output.path
  end
end
