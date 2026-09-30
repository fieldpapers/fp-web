ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

require 'minitest/reporters'
Minitest::Reporters.use!(
  Minitest::Reporters::SpecReporter.new,
  ENV,
  Minitest.backtrace_filter
)

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def capture_sql(&block)
    queries = []
    callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  end

  def create_user(username)
    User.create!(username: username, email: "#{username}@example.com", password: "password123")
  end

  def create_atlas(rows:, cols:, creator: nil)
    Atlas.create!(
      creator: creator,
      west: -122.3, south: 37.7, east: -122.2, north: 37.8,
      rows: rows, cols: cols, zoom: 14,
      provider: "https://tile.openstreetmap.org/{Z}/{X}/{Y}.png",
      layout: "full-page", orientation: "landscape", paper_size: "letter"
    )
  end

  # skips validation to avoid needing a real scene attachment
  def create_snapshot(atlas, page_number, slug, created_at: Time.now, uploader: nil)
    page = atlas.pages.find_by!(page_number: page_number)
    attrs = page.slice(:west, :south, :east, :north, :zoom)
      .merge(page: page, slug: slug, created_at: created_at, uploader: uploader)
    Snapshot.new(attrs).save!(validate: false)
  end
end
