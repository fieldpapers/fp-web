require "paper"
require "providers"
require "raven"

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
#  private        :boolean          default(FALSE), not null
#  cloned_from    :integer
#  refreshed_from :integer
#  created_at     :datetime
#  updated_at     :datetime
#  composed_at    :datetime
#  failed_at      :datetime
#  workflow_state :string(255)
#

class Atlas < ActiveRecord::Base
  include FriendlyId
  include Workflow

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
  after_initialize :apply_defaults
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

  # provider validation
  validate :provider_valid

  # TODO: will there be ever a case where provider can
  # have multiple URL templates not including OVERLAYS
  def provider_valid
    p = get_provider_without_overlay
    if /\Ahttps?:\/\/(\{[s]\})?[\/\w\.\-\?\+\*_\|~:\[\]@#!\$'\(\),=&]*\{[zxy]\}\/\{[zxy]\}\/\{[zxy]\}[\/\w\.\-\?\+\*_\|~:\[\]@#!\$'\(\),=&]*(jpg|png)([\/\w\.\-\?\+\*_\|~:\[\]@#!\$'\(\),=&]*)?\z/i !~ p
      errors.add(:provider, "Invalid URL template")
    end
  end

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
      .where("#{self.table_name}.failed_at is null")
      .order("created_at DESC")
  }

  scope :default, -> {
    includes(:creator)
      .where("#{self.table_name}.failed_at is null")
      .order("created_at DESC")
  }

  scope :by_creator, -> (creator) {
    if creator
      where("#{self.table_name}.private = false OR (#{self.table_name}.private = true AND #{self.table_name}.user_id = ?)", creator.id)
    else
      where("#{self.table_name}.private = false")
    end
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

  # workflow states

  workflow do
    state :new do
      event :render, transitions_to: :rendering
      event :fail, transitions_to: :failed
    end

    state :rendering do
      # TODO this can be simplified to if: :all_pages_rendered? once
      # workflow@1.3.0 is released
      event :rendered, transitions_to: :merging, if: proc { |x| x.send :all_pages_rendered? }
      event :rendered, transitions_to: :rendering
      event :fail, transitions_to: :failed
    end

    state :merging do
      event :merged, transitions_to: :complete
      event :fail, transitions_to: :failed
    end

    state :complete
    state :failed do
      event :fail, transitions_to: :failed
    end
  end

  # workflow transition event handlers

  def increment_progress
    # 2 = started, merged
    update(progress: self.progress += 1.0 / (pages.size + 2))
  end

  def merged
    increment_progress
  end

  def render
    increment_progress

    pages.each do |page|
      task = "render_page"
      task = "render_index" if page.page_number == "i"

      rsp = http_client.put "#{FieldPapers::TASK_BASE_URL}/#{task}", {
        task: task,
        callback_url: "#{FieldPapers::BASE_URL}/atlases/#{slug}/#{page.page_number}",
        page: page.as_json(include: {
          atlas: {
            only: [:slug, :layout, :orientation, :paper_size, :cols, :rows],
            methods: [:bbox]
          }
        },
        methods: [:bbox],
        only: [:page_number, :provider, :zoom]),
      }

      if rsp.status < 200 || rsp.status >= 300
        logger.warn("Got #{rsp.status}: #{rsp.body}")
        Raven.capture_exception(Exception.new("Got #{rsp.status}: #{rsp.body}"))
        fail!
      end
    end
  end

  def rendered
    increment_progress
  end

  def on_complete_entry(previous_state, event)
    update(composed_at: Time.now, progress: 1)
  end

  def on_failed_entry(previous_state, event)
    update(failed_at: Time.now)
  end

  def on_merging_entry(previous_state, event)
    task = "merge_pages"

    rsp = http_client.put "#{FieldPapers::TASK_BASE_URL}/#{task}", {
      task: task,
      callback_url: "#{FieldPapers::BASE_URL}/atlases/#{slug}",
      atlas: as_json(include: {pages: { only: [:page_number, :pdf_url] }}, only: [:slug]),
    }

    if rsp.status < 200 || rsp.status >= 300
      logger.warn("Got #{rsp.status}: #{rsp.body}")
      Raven.capture_exception(Exception.new("Got #{rsp.status}: #{rsp.body}"))
      fail!
    end
  end

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
    if self[:title].blank?
      "Untitled"
    else
      read_attribute(:title)
    end
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
    tmp = provider
    if redcross_overlay?
      tmp = tmp.gsub(OVERLAY_REDCROSS, "")
    end
    if utm_grid?
      tmp = tmp.gsub(OVERLAY_UTM, "")
    end
    return tmp
  end

  def conform_template(template)
    return template.gsub('{S}','{s}').gsub('{X}','{x}').gsub('{Y}','{y}').gsub('{Z}','{z}')
  end

  # split a concatenated provider string
  def provider_split
    positions = provider.enum_for(:scan, /https?/).map { Regexp.last_match.begin(0) }
    return positions.enum_for(:each_with_index).map { |x,i| provider[x..((positions[i+1] || 0)-1)] }
  end

  def complete?
    !composed_at.nil?
  end

  def incomplete?
    composed_at.nil? && failed_at.nil?
  end

  def failed?
    !failed_at.nil?
  end

private

  def all_pages_rendered?
    pages.all? do |page|
      page.complete?
    end
  end

  def apply_defaults
    self.progress ||= 0
    self.provider ||= ""
  end

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
    info = provider_info || {}

    info[:minzoom] ||= 0
    info[:maxzoom] ||= 18

    # clamp zoom to the available zoom range
    [info[:minzoom], z, info[:maxzoom]].sort[1]
  end

  def create_pages
    width = (east - west) / cols
    height = (north - south) / rows

    # create index page

    if rows * cols > 1
      horiz_padding = ((east - west) * INDEX_BUFFER_FACTOR).abs
      vert_padding = ((north - south) * INDEX_BUFFER_FACTOR).abs

      if rows > cols
        horiz_padding += width * cols / rows
      elsif cols > rows
        vert_padding += height * rows / cols
      end

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
        provider: provider.gsub(OVERLAY_UTM, "")
    end

    # create individual pages

    row_names = ("A".."Z").to_a

    rows.times do |y|
      cols.times do |x|
        left = west + (x * width)
        right = east - ((cols - x - 1) * width)

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

  def http_client
    @http_client ||= Faraday.new do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/

      faraday.adapter Faraday.default_adapter
    end
  end
end
