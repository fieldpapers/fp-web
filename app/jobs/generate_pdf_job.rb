class GeneratePdfJob < ActiveJob::Base
  queue_as :default

  def perform(slug)
    puts "Generating PDF for #{slug}"
  end
end
