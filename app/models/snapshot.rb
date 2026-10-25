require "providers"
require "uri"

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

class Snapshot < ActiveRecord::Base
  include FriendlyId
  include Processable
  include Rails.application.routes.url_helpers

  completed_at_column :decoded_at

  # friendly_id configuration

  friendly_id :random_id, use: :slugged

  # kaminari (pagination) configuration

  paginates_per 25

  # paperclip (attachment) configuration

  # TODO stick this in a Module and include/extend it accordingly
  case FieldPapers::PERSIST
  when "local"
    has_attached_file :scene, {
      hash_secret: "whatever",
      url: "/snapshots/:hash.:extension",
    }

    validates_attachment_content_type :scene, content_type: /\Aimage\/.*\Z/
  when "s3"
    def self.s3_url(bucket, region)
      %r{\Ahttps?:\/\/(?:s3\.)?(?:s3-)?(#{region})?\.?amazonaws\.com\/#{bucket}\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze
    end

    # Environment-specific direct upload url verifier screens for malicious posted upload locations.
    S3_UPLOAD_URL_FORMAT = s3_url(FieldPapers::S3_BUCKET_NAME,
                                  FieldPapers::AWS_REGION)

    has_attached_file :scene

    validates :s3_scene_url, presence: true, format: { with: S3_UPLOAD_URL_FORMAT }
    validates_attachment_content_type :scene, :content_type => /\Aimage\/.*\Z/
  end

  # callbacks
  after_initialize :apply_defaults

  # relations

  belongs_to :uploader,
    class_name: "User",
    foreign_key: :user_id

  belongs_to :page
  has_one :atlas, through: :page

  # scopes

  default_scope {
    includes([:atlas, :page, :uploader])
      .joins(:atlas)
      .where("#{self.table_name}.page_id IS NOT NULL")
      .where("#{self.table_name}.private = false")
      .where("#{Atlas.table_name}.private = false")
      .where("#{self.table_name}.failed_at IS NULL")
      .order("#{self.table_name}.created_at DESC")
  }

  scope :default, -> {
    includes([:atlas, :page, :uploader])
      .joins(:atlas)
      .where("#{self.table_name}.page_id IS NOT NULL")
      .where("#{self.table_name}.private = false")
      .where("#{Atlas.table_name}.private = false") # TODO update data to obviate this (only needed for legacy snapshots)
      .where("#{self.table_name}.failed_at IS NULL")
      .order("#{self.table_name}.created_at DESC")
  }

  scope :by_creator, -> (creator) {
    if creator
      where("#{self.table_name}.private = false OR (#{self.table_name}.private = true AND #{self.table_name}.user_id = ?)", creator.id)
    else
      where("#{self.table_name}.private = false")
        .where("#{Atlas.table_name}.private = false")
    end
  }

  scope :date,
    -> date {
      where(created_at: date.to_date.all_day)
    }

  scope :month,
    -> month {
      start = Date.strptime(month, "%Y-%m")
      where(created_at: start...(start >> 1))
    }

  scope :place,
    -> place {
      where("#{self.table_name}.place_woeid = ? OR #{self.table_name}.region_woeid = ? OR #{self.table_name}.country_woeid = ?", place, place, place)
    }

  scope :user,
    -> user {
      where(user_id: user)
    }

  scope :username,
    -> username {
      joins(:uploader)
      .where(users: {username: username})
    }
    
  # class methods

  # Hosts in the QR codes of printed atlases, besides BASE_URL's
  PRINT_HOSTS = ["fieldpapers.org", "www.fieldpapers.org", "fieldpapers-web.herokuapp.com"]

  # The page that the URL in a printed page's QR code refers to, or nil.
  # These are <base>/atlases/<slug>/<page>?bbox=... or, on older prints,
  # <base>/...?id=<slug>/<page>. Printed atlases are permanent, so every form
  # that has ever been printed must keep working.
  def self.page_for_href(href)
    uri = URI.parse(href)
    hosts = PRINT_HOSTS + [URI.parse(FieldPapers::BASE_URL).host]
    return unless uri.is_a?(URI::HTTP) && hosts.include?(uri.host&.downcase)

    slug, page_number = if uri.query&.include?("id=")
      CGI.parse(uri.query)["id"].first.to_s.split("/")
    else
      uri.path.split("/").last(2)
    end

    Atlas.unscoped.find_by(slug: slug)&.pages&.find_by(page_number: page_number)
  rescue URI::InvalidURIError
    nil
  end

  # instance methods

  def atlas_id
    page && page.atlas_id
  end

  def title
    "Page #{page.page_number} of #{atlas.title}"
  end

  def bbox
    [west, south, east, north]
  end

  def bbox=(bbox)
    if bbox.nil?
      write_attribute :west, nil
      write_attribute :south, nil
      write_attribute :east, nil
      write_attribute :north, nil
    else
      write_attribute :west, bbox[0]
      write_attribute :south, bbox[1]
      write_attribute :east, bbox[2]
      write_attribute :north, bbox[3]
    end
  end

  def provider
    if atlas
      atlas.get_provider_without_overlay
    else
      # TODO this is a really nasty way to achieve this
      Providers.layers[Providers.default]["template"]
    end
  end

  def image_url
    s3_scene_url || FieldPapers::STATIC_URI_PREFIX + scene.url
  end

  def image_filename
    return uploaded_file if uploaded_file
    return s3_scene_url.split("/").last if s3_scene_url
    scene_file_name.split("/").last
  end

  def latitude
    north + ((south-north)/2)
  end

  def longitude
    west + ((east-west)/2)
  end

  def uploader_name
    uploader && uploader.username || "anonymous"
  end

  def geometry_string
    return "POLYGON((%.6f %.6f,%.6f %.6f,%.6f %.6f,%.6f %.6f,%.6f %.6f))" % [west, south, west, north, east, north, east, south, west, south]
  end

  # store an unescaped version of the URL that Amazon returns from direct
  # upload
  def s3_scene_url=(escaped_url)
    write_attribute(:s3_scene_url, (CGI.unescape(escaped_url) rescue nil))
  end

  def as_polygon
    [[
      [west, south],
      [west, north],
      [east, north],
      [east, south],
      [west, south]
     ]]
  end

  def as_feature
    {
      type: 'Feature',
      properties: {
        type: 'snapshot',
        title: title,
        description: description,
        uploader: uploader_name,
        created: created_at.iso8601,
        min_row: min_row,
        max_row: max_row,
        min_column: min_column,
        max_column: max_column,
        min_zoom: min_zoom,
        max_zoom: max_zoom,
        base_url: base_url,
        url: snapshot_url(self),
        url_page: atlas_page_atlas_url(atlas, page.page_number),
        url_uploader: uploader ? snapshots_url(username: uploader.username) : nil,
      },
      geometry: {
        type: 'Polygon',
        coordinates: as_polygon
      }
    }
  end

  def as_json(options = nil)
    if options && options[:geojson]
      as_feature
    else
      super(options || {})
    end
  end

private

  def apply_defaults
    self.progress ||= 0
  end

  def random_id
    # use multiple attempts of a lambda for slug candidates

    25.times.map do
      -> {
        rand(2**256).to_s(36).ljust(8,'a')[0..7]
      }
    end
  end
end
