# == Schema Information
#
# Table name: atlases
#
#  id            :string(8)        not null, primary key
#  title         :text(65535)
#  form_id       :string(8)
#  north         :float(53)
#  south         :float(53)
#  east          :float(53)
#  west          :float(53)
#  zoom          :integer
#  paper_size    :string(6)        default("letter")
#  orientation   :string(9)        default("portrait")
#  layout        :string(9)        default("full-page")
#  provider      :string(255)
#  pdf_url       :string(255)
#  preview_url   :string(255)
#  geotiff_url   :string(255)
#  atlas_pages   :text(65535)
#  country_name  :string(64)
#  country_woeid :integer
#  region_name   :string(64)
#  region_woeid  :integer
#  place_name    :string(128)
#  place_woeid   :integer
#  user_id       :string(8)
#  created_at    :datetime         default("CURRENT_TIMESTAMP"), not null
#  composed_at   :datetime         default("0000-00-00 00:00:00"), not null
#  progress      :float(24)
#  private       :integer          not null
#  text          :text(16777215)
#  cloned        :string(20)
#  refreshed     :string(20)
#  updated_at    :datetime
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
      provider: "http://tile.openstreetmap.org/{z}/{x}/{y}.png",
      composed_at: Time.now # TODO this should default to NULL

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
