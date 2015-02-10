# == Schema Information
#
# Table name: pages
#
#  id            :integer
#  print_id      :text
#  page_number   :text
#  text          :text
#  bbox          :geometry({:srid= geometry, 0
#  zoom          :integer
#  provider      :text
#  preview_url   :text
#  country_name  :text
#  country_woeid :integer
#  region_name   :text
#  region_woeid  :integer
#  place_name    :text
#  place_woeid   :integer
#  user_id       :text
#  created       :datetime
#  composed      :datetime
#

require 'test_helper'

class PageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
