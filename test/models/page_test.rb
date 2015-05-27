# == Schema Information
#
# Table name: pages
#
#  id            :integer          not null, primary key
#  atlas_id      :integer          not null
#  page_number   :string(5)        not null
#  west          :float(53)        not null
#  south         :float(53)        not null
#  east          :float(53)        not null
#  north         :float(53)        not null
#  zoom          :integer
#  provider      :string(255)
#  preview_url   :string(255)
#  country_name  :string(64)
#  country_woeid :integer
#  region_name   :string(64)
#  place_name    :string(128)
#  place_woeid   :integer
#  created_at    :datetime
#  updated_at    :datetime
#  composed_at   :datetime
#  pdf_url       :string(255)
#

require 'test_helper'

class PageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
