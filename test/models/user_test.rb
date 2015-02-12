# == Schema Information
#
# Table name: new_users
#
#  id         :integer          default("0"), not null
#  slug       :string(8)        not null, primary key
#  name       :string(32)
#  password   :string(40)
#  email      :string(255)
#  created_at :datetime         default("0000-00-00 00:00:00"), not null
#  activated  :datetime         default("0000-00-00 00:00:00"), not null
#

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
