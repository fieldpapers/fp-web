Rails.application.configure do
  # this allows us to use url_helpers in models without passing all the args
  config.after_initialize do
    Rails.application.routes.default_url_options[:host] = ENV['BASE_URL']
  end
end
