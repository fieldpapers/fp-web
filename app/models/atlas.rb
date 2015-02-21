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

class Atlas < ActiveRecord::Base
  include FriendlyId

  # virtual fields for layer overlays
  attr_accessor :utm_grid, :redcross_overlay

  # friendly_id configuration

  friendly_id :random_id, use: :slugged

  # kaminari (pagination) configuration

  paginates_per 50

  # callbacks


  after_create :create_pages

  # validations

  validates :slug, presence: true
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
      order "page_number ASC"
    },
    dependent: :destroy,
    inverse_of: :atlas

  has_many :snapshots,
    -> {
      order "created_at DESC"
    },
    dependent: :destroy,
    inverse_of: :atlas

  # scopes

  default_scope {
    includes(:creator)
      .where("#{self.table_name}.private = false")
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

  def atlas_pages
    pages.size
  end

  # TODO this show go away if/when migrating to postgres
  def bbox
    [west, south, east, north]
  end

  def creator_name
    creator && creator.username || "anonymous"
  end

  def title
    read_attribute(:title) || "Untitled"
  end

private

  def random_id
    # use multiple attempts of a lambda for slug candidates

    25.times.map do
      -> {
        ('a'..'z').to_a.shuffle[0, 8].join
      }
    end
  end

  def create_pages
    row_names = ("A".."Z").to_a

    width = (east - west) / rows
    height = (north - south) / cols

    rows.times do |y|
      cols.times do |x|
        pages.create! \
          atlas_id: id,
          page_number: "#{row_names[y]}#{x + 1}",
          west: west + (x * width),
          south: south + ((cols - y - 1) * height),
          east: east - ((rows - x - 1) * width),
          north: north - (y * height),
          zoom: zoom,
          provider: provider
      end
    end
  end
end
