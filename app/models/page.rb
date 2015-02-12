# == Schema Information
#
# Table name: new_pages
#
#  id            :integer          default("0"), not null
#  print_id      :string(8)        not null
#  page_number   :string(5)        not null
#  text          :text(65535)
#  west          :float(53)
#  south         :float(53)
#  east          :float(53)
#  north         :float(53)
#  zoom          :integer
#  provider      :string(255)
#  preview_url   :string(255)
#  country_name  :string(64)
#  country_woeid :integer
#  region_name   :string(64)
#  region_woeid  :integer
#  place_name    :string(128)
#  place_woeid   :integer
#  user_id       :string(8)        not null
#  created       :datetime         default("0000-00-00 00:00:00"), not null
#  composed      :datetime         default("0000-00-00 00:00:00"), not null
#

class Page < ActiveRecord::Base
  self.primary_key = ["print_id", "page_number"]
  self.table_name = "new_pages"

  belongs_to :atlas,
    foreign_key: "print_id"

  # TODO this show go away if/when migrating to postgres
  def bbox
    [west, south, east, north]
  end
end
