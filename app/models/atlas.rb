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

  INDEX_BUFFER_FACTOR = 0.1
  OVERLAY_REDCROSS = "http://a.tiles.mapbox.com/v3/americanredcross.HAIYAN_Atlas_Bounds/{Z}/{X}/{Y}.png"
  OVERLAY_UTM = "http://tile.stamen.com/utm/{Z}/{X}/{Y}.png"

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
      order "FIELD(page_number, 'i') DESC, page_number ASC"
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

  # overlays (TODO generalize this, allowing overlays to be registered on
  # a system- and user-level (and group?))

  def redcross_overlay?
    provider.include? OVERLAY_REDCROSS
  end

  def redcross_overlay=(use_overlay)
    if use_overlay
      provider += OVERLAY_REDCROSS unless redcross_overlay?
    else
      provider = provider.gsub(OVERLAY_REDCROSS, "")
    end
  end

  def utm_grid?
    provider.include? OVERLAY_UTM
  end

  def utm_grid=(use_overlay)
    if use_overlay
      provider += OVERLAY_UTM unless utm_grid?
    else
      provider = provider.gsub(OVERLAY_UTM, "")
    end
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
    # create index page

    pages.create! \
      page_number: "i",
      west: west - west * INDEX_BUFFER_FACTOR,
      south: south - south * INDEX_BUFFER_FACTOR,
      east: east + east * INDEX_BUFFER_FACTOR,
      north: north + north * INDEX_BUFFER_FACTOR,
      zoom: zoom,
      # omit UTM overlays (if present) from the index page
      provider: provider.gsub("http://tile.stamen.com/utm/{Z}/{X}/{Y}.png", "")

    # create individual pages

    row_names = ("A".."Z").to_a

    width = (east - west) / rows
    height = (north - south) / cols

    rows.times do |y|
      cols.times do |x|
        pages.create! \
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
