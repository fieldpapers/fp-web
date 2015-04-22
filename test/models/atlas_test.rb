# == Schema Information
#
# Table name: atlases
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  slug           :string(8)        not null
#  title          :text(4294967295)
#  text           :text(4294967295)
#  west           :float(53)        not null
#  south          :float(53)        not null
#  east           :float(53)        not null
#  north          :float(53)        not null
#  zoom           :integer
#  rows           :integer          not null
#  cols           :integer          not null
#  provider       :string(255)
#  paper_size     :string(6)        default("letter"), not null
#  orientation    :string(9)        default("portrait"), not null
#  layout         :string(9)        default("full-page"), not null
#  pdf_url        :string(255)
#  preview_url    :string(255)
#  country_name   :string(64)
#  country_woeid  :integer
#  region_name    :string(64)
#  region_woeid   :integer
#  place_name     :string(128)
#  place_woeid    :integer
#  progress       :float(24)
#  private        :boolean          default("0"), not null
#  cloned_from    :integer
#  refreshed_from :integer
#  created_at     :datetime
#  updated_at     :datetime
#  composed_at    :datetime
#  failed_at      :datetime
#

require 'test_helper'

class AtlasTest < ActiveSupport::TestCase
  def assert_bounds(page, west, south, east, north)
    assert_equal west, page.west
    assert_equal south, page.south
    assert_equal east, page.east
    assert_equal north, page.north
  end

  test "#create creates associated pages" do
    west = -122.3789
    south = 47.5771
    east = -122.2931
    north = 47.6349

    atlas = Atlas.create! \
      cols: 2,
      rows: 2,
      west: west,
      south: south,
      east: east,
      north: north,
      zoom: 13,
      provider: "http://{S}.tile.openstreetmap.org/{Z}/{X}/{Y}.png"

    assert_equal 5, atlas.pages.size

    assert_equal "i", atlas.pages[0].page_number
    assert_equal "A1", atlas.pages[1].page_number
    assert_equal "A2", atlas.pages[2].page_number
    assert_equal "B1", atlas.pages[3].page_number
    assert_equal "B2", atlas.pages[4].page_number

    assert_bounds atlas.pages[1], west, (north + south) / 2, (west + east) / 2, north
    assert_bounds atlas.pages[2], (west + east) / 2, (north + south) / 2, east, north
    assert_bounds atlas.pages[3], west, south, (west + east) / 2, (north + south) / 2
    assert_bounds atlas.pages[4], (west + east) / 2, south, east, (north + south) / 2

    buffered_west = west - ((east - west) * 0.1).abs
    buffered_south = south - ((north - south) * 0.1).abs
    buffered_east = east + ((east - west) * 0.1).abs
    buffered_north = north + ((north - south) * 0.1).abs

    assert_bounds atlas.pages[0], buffered_west, buffered_south, buffered_east, buffered_north
  end
end
