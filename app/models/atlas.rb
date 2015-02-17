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

class Atlas < ActiveRecord::Base
  # virtual fields for layer overlays
  attr_accessor :utm_grid, :redcross_overlay

  # kaminari (pagination) configuration

  paginates_per 50

  # generate a random id (since id is not currently auto-increment)
  after_initialize :init

  # validations

  validates :west, :south, :east, :north, numericality: true
  validates :zoom, :rows, :cols, numericality: { only_integer: true }
  validates :provider, presence: true
  validates :layout, :orientation, :paper_size, presence: true

  # the following properties have default values (from the db), so they'll
  # successfully validate before they're overridden

  validates :layout, inclusion: {
    in: ["full-page", "half-page"],
    message: "%{value} is not a valid layout"
  }

  validates :orientation, inclusion: {
    in: ["portrait", "landscape"],
    message: "%{value} is not a valid orientation"
  }

  validates :paper_size, inclusion: {
    in: ["letter", "a3", "a4"], # TODO more paper sizes
    message: "%{value} is not a supported paper size"
  }

  # relations

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

  has_many :snapshots,
    -> {
      order "created_at DESC"
    },
    dependent: :destroy,
    inverse_of: :atlas,
    foreign_key: "print_id"

  # scopes

  default_scope {
    includes(:creator)
      .where("private = 0")
      .order("created_at DESC")
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

  # TODO this show go away if/when migrating to postgres
  def bbox
    [west, south, east, north]
  end

  def creator_name
    creator && creator.username || "anonymous"
  end

  # TODO remove this once atlases get proper ids
  def init
    self.id ||= ('a'..'z').to_a.shuffle[0,8].join
  end

  def title
    read_attribute(:title) || "Untitled"
  end
end
