# == Schema Information
#
# Table name: new_atlases
#
#  id            :integer          default("0"), not null
#  slug          :string(8)        not null, primary key
#  title         :text(65535)
#  form_id       :string(8)
#  west          :float(53)
#  south         :float(53)
#  east          :float(53)
#  north         :float(53)
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
#  created_at    :datetime         default("0000-00-00 00:00:00"), not null
#  updated_at    :datetime         default("0000-00-00 00:00:00"), not null
#  composed      :datetime         default("0000-00-00 00:00:00"), not null
#  progress      :float(24)
#  private       :integer          not null
#  text          :text(16777215)
#  cloned        :string(20)
#  refreshed     :string(20)
#

class Atlas < ActiveRecord::Base
  self.primary_key = "slug"
  self.table_name = "new_atlases"

  belongs_to :creator,
    class_name: "User",
    foreign_key: "user_id"

  has_many :pages,
    -> {
      order "page_number DESC"
    },
    dependent: :destroy,
    inverse_of: :atlas,
    foreign_key: "print_id"

  # TODO this show go away if/when migrating to postgres
  def bbox
    [west, south, east, north]
  end

  def creator_name
    self.creator && self.creator.name || "anonymous"
  end

  def title
    @title || "Untitled"
  end
end
