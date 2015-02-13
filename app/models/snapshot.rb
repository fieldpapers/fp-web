# == Schema Information
#
# Table name: new_snapshots
#
#  id                :integer          default("0"), not null
#  slug              :string(8)        not null, primary key
#  print_id          :string(8)
#  print_page_number :string(5)        not null
#  print_href        :text(65535)
#  min_row           :float(24)
#  min_column        :float(24)
#  min_zoom          :integer
#  max_row           :float(24)
#  max_column        :float(24)
#  max_zoom          :integer
#  description       :text(65535)
#  is_private        :string(3)        default("no")
#  will_edit         :string(3)        default("yes")
#  has_geotiff       :string(3)        default("no")
#  has_geojpeg       :string(3)        default("no")
#  has_stickers      :string(3)        default("no")
#  base_url          :string(255)
#  uploaded_file     :string(255)
#  geojpeg_bounds    :text(65535)
#  decoding_json     :text(65535)
#  country_name      :string(64)
#  country_woeid     :integer
#  region_name       :string(64)
#  region_woeid      :integer
#  place_name        :string(128)
#  place_woeid       :integer
#  user_id           :string(8)
#  created_at        :datetime         default("0000-00-00 00:00:00"), not null
#  decoded_at        :datetime         default("0000-00-00 00:00:00"), not null
#  failed            :integer          default("0")
#  progress          :float(24)
#

class Snapshot < ActiveRecord::Base
  # configuration

  self.primary_key = "slug"
  self.table_name = "new_snapshots"

  # kaminari (pagination) configuration

  paginates_per 50

  # relations

  belongs_to :uploader,
    class_name: "User",
    foreign_key: :user_id

  belongs_to :page,
    foreign_key: [:print_id, :print_page_number]

  belongs_to :atlas,
    foreign_key: :print_id

  # scopes

  default_scope {
    includes([:atlas, :page, :uploader])
      .joins(:atlas)
      .where("#{self.table_name}.print_id IS NOT NULL AND is_private = 'no' AND #{Atlas.table_name}.private = 0")
      .order("#{self.table_name}.created_at DESC")
  }

  scope :date,
    -> date {
      where("DATE(created_at) = ?", date)
    }

  scope :month,
    -> month {
      where("CONCAT(YEAR(created_at), '-', LPAD(MONTH(created_at), 2, '0')) = ?", month)
    }

  scope :place,
    -> place {
      where("place_woeid = ? OR region_woeid = ? OR country_woeid = ?", place, place, place)
    }

  scope :user,
    -> user {
      where(user_id: user)
    }

  # instance methods

  def title
    "Page #{print_page_number} of #{atlas.title}"
  end

  def uploader_name
    uploader && uploader.name || "anonymous"
  end
end
