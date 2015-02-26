require "timeout"

class GeneratePdfJob < ActiveJob::Base
  queue_as :default

  def perform(atlas)
    base_cmd = %w(docker run fieldpapers/paper)

    files = atlas.pages.map do |page|
      cmd = base_cmd.dup

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

        raise "Timed out waiting to render page #{page.page_number} of #{atlas.slug}"
      end

      unless status.success?
        raise "Failed to render page #{page.page_number} of #{atlas.slug}"
      end

      output = Tempfile.new(["page", ".pdf"], "tmp/")

      IO.copy_stream(pipe, output)

      output.path
    end

    if atlas.pages.size > 1
      gs = %w(gs -q -sDEVICE=pdfwrite -o -)

      gs.concat(files)

      pdf = IO.popen(gs)

      (pid, status) = Process.wait2(pdf.pid)

      unless status.success?
        raise "Failed to merge pages for #{atlas.slug}"
      end

      atlas = Tempfile.new(["atlas", ".pdf"], "tmp/")

      IO.copy_stream(pdf, atlas)

      # upload file to S3
      # attach file to Atlas

      puts "atlas: #{atlas.path}"
    else
      # upload file to S3
      # attach file to Atlas

      puts "atlas: #{files.first}"
    end
  end
end
