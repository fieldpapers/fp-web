# In "production", we are running on an AWS EC2 instance.  In this
# environment, AWS requires an additional piece of authentication
# information to allow email to be sent using SES.  This is a "mail
# source ARN", used to associate the sending EC2 instance with a mail
# identity policy.
#
# In "development", if you're trying to use SES as a mail delivery
# method, it's assumed that you have AWS credentials set up
# appropriately via environment variables.

if Rails.env.production?
  ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
    :source_arn => ENV['MAIL_SOURCE_ARN']
else
  ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base
end
