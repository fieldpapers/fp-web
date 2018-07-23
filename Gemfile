source "https://rubygems.org"

ruby "2.4.4"

## standard dependencies

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "4.2.10"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
gem 'font-awesome-sass'
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"
# Use jquery as the JavaScript library
gem "jquery-rails"
gem "selectize-rails"
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem "turbolinks"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.0"
# bundle exec rake doc:rails generates the API under doc/api.
gem "sdoc", "~> 1.0.0", group: :doc

## explicit choices

gem "aws-sdk-v1", "~> 1"
gem "aws-sdk-core", "~> 2"
gem "aws-ses", :require => 'aws/ses', git: 'https://github.com/Cadasta/aws-ses'
gem "bootstrap-sass", "~> 3.3.3"
gem "composite_primary_keys", "~> 8.0.0"
gem "devise", "~> 3.5.10" # authentication
gem "devise-i18n" # Devise translations
gem "devise-i18n-views" # internationalized views for Devise
gem "faraday" # http client
gem "faraday_middleware" # response parsing, etc.
gem "friendly_id", "~> 5.1.0" # alphanumeric slugs
gem "gettext_i18n_rails" # gettext-style i18n
gem "has_scope" # automatic filter generation
gem "http_accept_language"
gem "kaminari" # pagination
gem "kaminari-i18n"
gem "leaflet-rails", git: 'https://github.com/stamen/leaflet-rails'
gem "paperclip", "~> 4.3.1" # file attachments
gem "puma" # app server
gem "rack-contrib"
gem "rack-rewrite" # URL rewriting middleware
gem "rails-i18n", "~> 4.0.0"
gem "s3_direct_upload", git: 'https://github.com/Cadasta/s3_direct_upload'
gem "pg"
gem "workflow"
gem "json"
gem 'geo', git: 'https://github.com/ollie/geo-mercator.git'
gem 'actionview-encoded_mail_to'
gem 'therubyracer', '~> 0.12.3'
gem 'mapbox-rails', git: 'https://github.com/aai/mapbox-rails'

## production-only dependencies

group :production do
  gem "rails_12factor" # Heroku compatibility
  gem "sentry-raven" # exception logging
end

## development-only dependencies

group :development do
  gem "annotate", "~> 2.6.5" # model annotation

  gem "gettext", ">= 3.0.2", require: false
  gem "guard"
  gem "guard-annotate"
  gem "guard-bundler", require: false
  gem "guard-livereload", "~> 2.4", require: false
  gem "guard-minitest"
  gem "foreman"

  gem "quiet_assets"

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 2.0"
end

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug"

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"

  gem "meta_request" # to support https://github.com/dejan/rails_panel
  gem "minitest-reporters"

  gem "rake"
end
