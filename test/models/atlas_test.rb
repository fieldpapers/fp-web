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
#

require 'test_helper'

class AtlasTest < ActiveSupport::TestCase
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
      provider: "http://tile.openstreetmap.org/{z}/{x}/{y}.png"

    assert_equal 4, atlas.pages.size

    assert_equal "A1", atlas.pages[0].page_number
    assert_equal "A2", atlas.pages[1].page_number
    assert_equal "B1", atlas.pages[2].page_number
    assert_equal "B2", atlas.pages[3].page_number

    assert_equal west, atlas.pages[0].west
    assert_equal (north + south) / 2, atlas.pages[0].south
    assert_equal (west + east) / 2, atlas.pages[0].east
    assert_equal north, atlas.pages[0].north

    assert_equal (west + east) / 2, atlas.pages[1].west
    assert_equal (north + south) / 2, atlas.pages[1].south
    assert_equal east, atlas.pages[1].east
    assert_equal north, atlas.pages[1].north

    assert_equal west, atlas.pages[2].west
    assert_equal south, atlas.pages[2].south
    assert_equal (west + east) / 2, atlas.pages[2].east
    assert_equal (north + south) / 2, atlas.pages[2].north

    assert_equal east, atlas.pages[3].east
    assert_equal south, atlas.pages[3].south
    assert_equal (west + east) / 2, atlas.pages[3].west
    assert_equal (north + south) / 2, atlas.pages[3].north
  end
end
