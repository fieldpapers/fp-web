class ActionMailer::Base
  def defaults
    headers['X-SES-FROM-ARN'] = ENV["MAIL_SOURCE_ARN"]
  end
end
