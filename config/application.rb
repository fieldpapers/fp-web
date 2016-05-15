require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # rewrite URLs for backward-compatibility
    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      # handle both encoded and non-encoded /s
      rewrite %r{^/atlas.php(\?id=(.*)%2F(.*))?$}, "/atlases/$2/$3"
      rewrite %r{^/atlas.php(\?id=(.*))?$}, "/atlases/$2"
      rewrite "/atlases.php", "/atlases"
      rewrite %r{^/snapshot.php(\?id=(.*))?$}, "/snapshots/$2"
      rewrite "/snapshots.php", "/snapshots"

      # this S3 bucket is hard-coded here because these requests are purely
      # legacy requests
      r301 %r{^/files/prints/(.*)}, "http://s3.amazonaws.com/files.fieldpapers.org/atlases/$1"
      r301 %r{^/files/scans/(.*)}, "http://s3.amazonaws.com/files.fieldpapers.org/snapshots/$1"
    end

    # this allows us to use url_helpers in models without passing all the args
    config.after_initialize do
      Rails.application.routes.default_url_options[:host] = FieldPapers::BASE_URL
    end

    # if there is an environment variable ATLAS_MAP_OVERVIEW_TILELAYER
    # then use that value as the atlas index map overview tilelayer
    config.atlas_index_overview_tilelayer = ENV['ATLAS_INDEX_OVERVIEW_TILELAYER'] || "http://{s}.tile.stamen.com/toner/{z}/{x}/{y}.png"
    config.atlas_index_overview_attribution = config.atlas_index_overview_tilelayer.include?('tile.stamen.com') ?
      'Map tiles by <a href="http://stamen.com/">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org/">OpenStreetMap</a>, under <a href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>.' :
      ''
  end
end
