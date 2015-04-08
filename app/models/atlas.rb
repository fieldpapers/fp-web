require "paper"
require "providers"

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
  BASE_ZOOM = 22 # zoom level to use for pixel calculations
  TARGET_RESOLUTION_PPI = 150 # target resolution for printing

  # virtual attributes

  attr_accessor :redcross_overlay, :utm_grid

  # friendly_id configuration

  friendly_id :random_id, use: :slugged

  # kaminari (pagination) configuration

  paginates_per 50

  # callbacks

  after_create :create_pages
  after_create :generate_pdf
  before_save :handle_overlays
  before_save :pick_zoom

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
    in: ["letter", "a3", "a4"], # TODO more paper sizes (from paper.rb)
    message: "%{value} is not a supported paper size"
  }

  # relations

  belongs_to :creator,
    class_name: "User",
    foreign_key: "user_id"

  has_many :pages,
    -> {
      order "FIELD(#{Page.table_name}.page_number, 'i') DESC, #{Page.table_name}.page_number ASC"
    },
    dependent: :destroy,
    inverse_of: :atlas

  has_many :snapshots,
    -> {
      order "#{Snapshot.table_name}.created_at DESC"
    },
    through: :pages,
    inverse_of: :atlas

  # scopes

  default_scope {
    includes(:creator)
      .where("#{self.table_name}.private = false")
      .order("created_at DESC")
  }

  scope :date,
    -> date {
      where("DATE(#{self.table_name}.created_at) = ?", date)
    }

  scope :month,
    -> month {
      where("CONCAT(YEAR(#{self.table_name}.created_at), '-', LPAD(MONTH(#{self.table_name}.created_at), 2, '0')) = ?", month)
    }

  scope :place,
    -> place {
      where("#{self.table_name}.place_woeid = ? OR #{self.table_name}.region_woeid = ? OR #{self.table_name}.country_woeid = ?", place, place, place)
    }

  scope :user,
    -> user {
      where(user_id: user)
    }

  # instance methods

  def atlas_pages
    pages.size
  end

  # TODO this should go away if/when migrating to postgres
  def bbox
    [west, south, east, north]
  end

  def latitude
    north + ((south-north)/2)
  end

  def longitude
    west + ((east-west)/2)
  end

  def geometry_string
    polys = []
    pages.each do |p|
      polys.push('((%.6f %.6f,%.6f %.6f,%.6f %.6f,%.6f %.6f,%.6f %.6f))' % [west, south, west, north, east, north, east, south, west, south])
    end
    return "MULTIPOLYGON(%s)" % polys.join(', ')
  end

  def creator_name
    creator && creator.username || "anonymous"
  end

  def title
    read_attribute(:title) || "Untitled"
  end

  # probably can get rid of this once migrated
  def get_rows
    if rows > 0
      rows
    else
      c = Array.new
      pages.each do |p|
        if p.page_number != 'i'
          rowcol = p.page_number.split('')
          if !c.include?(rowcol[0])
            c.push(rowcol[0])
          end
        end
      end
      c.size
    end
  end

  # probably can get rid of this once migrated
  def get_cols
    if cols > 0
      cols
    else
      c = Array.new
      pages.each do |p|
        if p.page_number != 'i'
          rowcol = p.page_number.split('')
          if !c.include?(rowcol[1])
            c.push(rowcol[1])
          end
        end
      end
      c.size
    end
  end

  # overlays (TODO generalize this, allowing overlays to be registered on
  # a system- and user-level (and group?))

  def redcross_overlay?
    provider.include? OVERLAY_REDCROSS
  end

  def utm_grid?
    provider.include? OVERLAY_UTM
  end

  def get_provider_without_overlay
    if redcross_overlay?
      provider.gsub(OVERLAY_REDCROSS, "")
    elsif utm_grid?
      provider.gsub(OVERLAY_UTM, "")
    else
      provider
    end
  end

private

  def random_id
    # use multiple attempts of a lambda for slug candidates

    25.times.map do
      -> {
        rand(2**256).to_s(36).ljust(8,'a')[0..7]
      }
    end
  end

  def canvas_size
    # TODO require this as a hidden field
    Paper.canvas_size(paper_size || "letter", orientation)
  end

  def provider_info
    # derive the key name for provider
    provider_key = Providers.derive provider

    Providers.layers.select do |k,v|
      k.to_s == provider_key
      #v[:template] == provider
    end.values.first
  end

  def calculate_zoom(west, east)
    z = (BASE_ZOOM - Math.log2((((east * (2**(BASE_ZOOM + 8))) / 360) - ((west * (2**(BASE_ZOOM + 8))) / 360)) / (canvas_size[0] * TARGET_RESOLUTION_PPI))).round
    info = provider_info

    # clamp zoom to the available zoom range
    if !info.nil?
      [info[:minzoom], z, info[:maxzoom]].sort[1]
    else
      [0, z, 18].sort[1]
    end
  end

  def create_pages
    # create index page

    if rows * cols > 1
      horiz_padding = ((east - west) * INDEX_BUFFER_FACTOR).abs
      vert_padding = ((north - south) * INDEX_BUFFER_FACTOR).abs
      left = west - horiz_padding
      right = east + horiz_padding

      pages.create! \
        page_number: "i",
        west: left,
        south: south - vert_padding,
        east: right,
        north: north + vert_padding,
        zoom: calculate_zoom(left, right),
        # omit UTM overlays (if present) from the index page
        provider: provider.gsub("http://tile.stamen.com/utm/{Z}/{X}/{Y}.png", "")
    end

    # create individual pages

    row_names = ("A".."Z").to_a

    width = (east - west) / cols
    height = (north - south) / rows

    rows.times do |y|
      cols.times do |x|
        left = west + (x * width)
        right = east - ((cols - x - 1) * width)

        z = (BASE_ZOOM - Math.log2((((right * (2**(BASE_ZOOM + 8))) / 360) - ((left * (2**(BASE_ZOOM + 8))) / 360)) / (canvas_size[0] * TARGET_RESOLUTION_PPI))).round

        pages.create! \
          page_number: "#{row_names[y]}#{x + 1}",
          west: west + (x * width),
          south: south + ((rows - y - 1) * height),
          east: east - ((cols - x - 1) * width),
          north: north - (y * height),
          zoom: calculate_zoom(left, right),
          provider: provider
      end
    end
  end

  # huh?
  def handle_overlays
    if redcross_overlay == "1"
      self.provider += OVERLAY_REDCROSS unless redcross_overlay?
    else
      self.provider = self.provider.gsub(OVERLAY_REDCROSS, "")
    end

    if utm_grid == "1"
      self.provider += OVERLAY_UTM unless utm_grid?
    else
      self.provider = self.provider.gsub(OVERLAY_UTM, "")
    end
  end

  # pick an appropriate zoom given the provided bounding box
  def pick_zoom
    self.zoom = calculate_zoom(west, east)
  end

  def generate_pdf
    GeneratePdfJob.perform_later(self)
  end
end
