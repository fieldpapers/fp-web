# == Schema Information
#
# Table name: atlases
#
#  id            :integer
#  slug          :text             primary key
#  title         :text
#  form_id       :text
#  bbox          :geometry
#  zoom          :integer
#  paper_size    :text
#  orientation   :text
#  layout        :text
#  provider      :text
#  pdf_url       :text
#  preview_url   :text
#  geotiff_url   :text
#  atlas_pages   :text
#  country_name  :text
#  country_woeid :integer
#  region_name   :text
#  region_woeid  :integer
#  place_name    :text
#  place_woeid   :integer
#  user_id       :text
#  created_at    :datetime
#  updated_at    :datetime
#  composed      :datetime
#  progress      :float
#  private       :boolean
#  text          :text
#  cloned        :text
#  refreshed     :text
#

require 'test_helper'

class AtlasTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
