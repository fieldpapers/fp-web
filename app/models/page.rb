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

class Page < ActiveRecord::Base
  self.primary_key = ["print_id", "page_number"]

  belongs_to :atlas,
    foreign_key: "print_id"
end
