# == Schema Information
#
# Table name: atlases
#
#  id            :integer
#  slug          :text             primary key
#  title         :text
#  form_id       :text
#  bbox          :geometry({:srid= geometry, 0
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

class Atlas < ActiveRecord::Base
  self.primary_key = "slug"
  has_many :pages,
    -> {
      order "page_number DESC"
    },
    dependent: :destroy,
    inverse_of: :atlas,
    foreign_key: "print_id"
end
