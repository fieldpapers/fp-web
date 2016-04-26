# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

GettextI18nRails.translations_are_html_safe = true

Rails.application.configure do
  # this allows us to use url_helpers in models without passing all the args
  config.after_initialize do
    Rails.application.routes.default_url_options[:host] = ENV['BASE_URL']
  end
end
