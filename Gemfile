source "https://rubygems.org"

ruby "3.1.3"

## standard dependencies

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "7.0.4.3"
# Use SCSS for stylesheets
gem "sass-rails", "~> 6.0.0"
gem 'font-awesome-sass'
# Use terser-ruby as compressor for JavaScript assets
gem "terser", ">= 1.1.14"
# Use jquery as the JavaScript library
gem "jquery-rails"
gem "selectize-rails"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.11.5"
# bundle exec rake doc:rails generates the API under doc/api.
gem "sdoc", "~> 2.6.1", group: :doc

## explicit choices

gem "aws-sdk-core", "~> 3"
gem "aws-sdk-s3", '~> 1.182'
gem 'aws-sdk-rails', '~> 3.7', '>= 3.7.1'
gem "bootstrap-sass", "~> 3.4.1"
gem "composite_primary_keys", "~> 14.0.6"
gem "devise", "~> 4.9.2" # authentication
gem "devise-i18n" # Devise translations
gem "devise-i18n-views" # internationalized views for Devise
gem "faraday" # http client
gem "faraday_middleware" # response parsing, etc.
gem "friendly_id", "~> 5.5.0" # alphanumeric slugs
gem "gettext_i18n_rails", "~> 1.13.0" # gettext-style i18n
gem "has_scope" # automatic filter generation
gem "http_accept_language"
gem "kaminari" # pagination
gem "kaminari-i18n"
gem "leaflet-rails", git: 'https://github.com/stamen/leaflet-rails'
gem "paperclip", "~> 6.1.0" # file attachments
gem "puma", "~> 6.6.0" # app server
gem "rack-contrib"
gem "rack-rewrite" # URL rewriting middleware
gem "rails-i18n", "~> 7.0.6"
gem "s3_direct_upload", git: 'https://github.com/waynehoover/s3_direct_upload'
gem "mysql2", "~> 0.5.6"
gem "workflow", "~> 3.0.0"
gem "json", "~> 2.6.3"
gem 'geo', git: 'https://github.com/ollie/geo-mercator.git'
gem 'actionview-encoded_mail_to'
gem 'mapbox-rails', git: 'https://github.com/aai/mapbox-rails'

## production-only dependencies

group :production do
  gem "rails_12factor" # Heroku compatibility
  gem "sentry-ruby" # exception logging
  gem "sentry-rails"
end

## development-only dependencies

group :development do
  gem "annotate", "~> 3.2.0" # model annotation

  gem "gettext", ">= 3.4.3", require: false
  gem "guard"
  gem "guard-bundler", require: false
  gem "guard-livereload", "~> 2.5.2", require: false
  gem "guard-minitest"
  gem "foreman"

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 4.2.0"
end

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug"

  gem "meta_request" # to support https://github.com/dejan/rails_panel
  gem "minitest-reporters"

  gem "rake"
end
