# == Schema Information
#
# Table name: users
#
#  id                     :string(8)        not null, primary key
#  name                   :string(32)
#  password               :string(40)
#  email                  :string(255)
#  hash                   :string(32)       not null
#  created                :datetime         default("CURRENT_TIMESTAMP"), not null
#  activated              :datetime         default("0000-00-00 00:00:00"), not null
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  updated_at             :datetime
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
