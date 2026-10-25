# == Schema Information
#
# Table name: snapshots
#
#  id                 :integer          not null, primary key
#  slug               :string(8)        not null
#  user_id            :integer
#  page_id            :integer
#  print_href         :text(65535)
#  min_row            :float(24)
#  max_row            :float(24)
#  min_column         :float(24)
#  max_column         :float(24)
#  min_zoom           :integer
#  max_zoom           :integer
#  description        :text(4294967295)
#  private            :boolean          default(FALSE), not null
#  has_geotiff        :string(3)        default("no")
#  has_geojpeg        :string(3)        default("no")
#  base_url           :string(255)
#  uploaded_file      :string(255)
#  country_name       :string(64)
#  country_woeid      :integer
#  region_name        :string(64)
#  region_woeid       :integer
#  place_name         :string(128)
#  place_woeid        :integer
#  progress           :float(24)
#  created_at         :datetime
#  updated_at         :datetime
#  decoded_at         :datetime
#  scene_file_name    :string(255)
#  scene_content_type :string(255)
#  scene_file_size    :integer
#  scene_updated_at   :datetime
#  s3_scene_url       :string(255)
#  west               :float(24)
#  south              :float(24)
#  east               :float(24)
#  north              :float(24)
#  zoom               :integer
#  geotiff_url        :string(255)
#  failed_at          :datetime
#

require 'test_helper'

class SnapshotTest < ActiveSupport::TestCase
  setup do
    @atlas = create_atlas(rows: 2, cols: 2)
    @atlas.update_column(:private, true)
    @page = @atlas.pages.find_by!(page_number: "B2")
  end

  test "page_for_href finds pages from printed QR codes" do
    slug = @atlas.slug
    base = URI.parse(FieldPapers::BASE_URL)

    [
      "https://fieldpapers.org/atlases/#{slug}/B2?bbox=-122.25,37.7,-122.2,37.75",
      "http://fieldpapers.org/atlases/#{slug}/B2?bbox=-122.25,37.7,-122.2,37.75",
      "https://www.fieldpapers.org/atlases/#{slug}/B2",
      "http://fieldpapers-web.herokuapp.com/atlases/#{slug}/B2?bbox=-122.25,37.7,-122.2,37.75",
      "#{base.scheme}://#{base.host}:#{base.port}/atlases/#{slug}/B2",
      "http://fieldpapers.org/atlas.php?id=#{slug}/B2",
      "http://fieldpapers.org/atlas.php?id=#{slug}%2FB2",
    ].each do |href|
      assert_equal @page, Snapshot.page_for_href(href), href
    end

    assert_equal @atlas.pages.find_by!(page_number: "i"), Snapshot.page_for_href("https://fieldpapers.org/atlases/#{slug}/i")
  end

  test "page_for_href ignores unknown pages and hosts" do
    slug = @atlas.slug

    [
      "https://example.com/atlases/#{slug}/B2",
      "ftp://fieldpapers.org/atlases/#{slug}/B2",
      "https://fieldpapers.org/atlases/#{slug}/C9",
      "https://fieldpapers.org/atlases/nope1234/B2",
      "https://fieldpapers.org/atlases/#{slug}",
      "https://fieldpapers.org/",
      "http://fieldpapers.org/atlas.php?id=#{slug}",
      "not a url",
      "",
    ].each do |href|
      assert_nil Snapshot.page_for_href(href), href
    end
  end
end
