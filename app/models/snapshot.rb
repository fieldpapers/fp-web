require "providers"
require "raven"

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
  include Workflow

  # Environment-specific direct upload url verifier screens for malicious posted upload locations.
  S3_UPLOAD_URL_FORMAT = %r{\Ahttps:\/\/s3\.amazonaws\.com\/#{Rails.application.secrets.aws["s3_bucket_name"]}\/(?<path>uploads\/.+\/(?<filename>.+))\z}.freeze

  # friendly_id configuration

  friendly_id :random_id, use: :slugged

  # kaminari (pagination) configuration

  paginates_per 25

  # paperclip (attachment) configuration

  has_attached_file :scene

  # callbacks
  after_initialize :apply_defaults

  # validations

  validates :s3_scene_url, presence: true, format: { with: S3_UPLOAD_URL_FORMAT }

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

  # validations

  validates_attachment_content_type :scene, :content_type => /\Aimage/

  # workflow states

  workflow do
    state :new do
      event :process, transitions_to: :processing
      event :fail, transitions_to: :failed
    end

    state :processing do
      event :processed, transitions_to: :fetching_metadata
      event :fail, transitions_to: :failed
    end

    state :fetching_metadata do
      event :metadata_fetched, transitions_to: :complete
      event :fail, transitions_to: :failed
    end

    state :complete
    state :failed
  end

  # workflow transition event handlers

  def increment_progress
    update(progress: self.progress += 1.0 / 4)
  end

  def process
    increment_progress

    task = "process_snapshot"

    rsp = http_client.put "#{FieldPapers::TASK_BASE_URL}/#{task}", {
      task: task,
      callback_url: "#{FieldPapers::BASE_URL}/snapshots/#{slug}",
      snapshot: as_json(methods: [:image_url], only: [:slug]),
    }

    if rsp.status < 200 || rsp.status >= 300
      logger.warn("Got #{rsp.status}: #{rsp.body}")
      Raven.capture_exception(Exception.new("Got #{rsp.status}: #{rsp.body}"))
      fail!
    end
  end

  def processed
    increment_progress

    task = "fetch_snapshot_metadata"

    rsp = http_client.put "#{FieldPapers::TASK_BASE_URL}/#{task}", {
      task: task,
      callback_url: "#{FieldPapers::BASE_URL}/snapshots/#{slug}",
      snapshot: as_json(methods: [:image_url], only: [:slug]),
    }

    if rsp.status < 200 || rsp.status >= 300
      logger.warn("Got #{rsp.status}: #{rsp.body}")
      Raven.capture_exception(Exception.new("Got #{rsp.status}: #{rsp.body}"))
      fail!
    end
  end

  def on_complete_entry(previous_state, event)
    updates = {
      decoded_at: Time.now,
      progress: 1,
    }

    uri = URI.parse(page_url)
    base_uri = URI.parse(FieldPapers::BASE_URL)

    if uri.hostname == base_uri.hostname && uri.port == base_uri.port
      (atlas_slug, page_number) = if uri.query
        CGI.parse(uri.query)["id"][0].split("/")
      else
        uri.path.split("/").slice(-2, 2)
      end

      if atlas_slug && page_number
        begin
          updates[:page] = Atlas.unscoped.friendly.find(atlas_slug).pages.find_by_page_number(page_number)
        rescue ActiveRecord::RecordNotFound
        end
      end
    end

    update(updates)
  end

  def on_failed_entry(previous_state, event)
    update(failed_at: Time.now)
  end

  def metadata_fetched
    increment_progress
  end

  # instance methods

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
      Providers.layers[Providers.default.to_sym][:template]
    end
  end

  def image_url
    s3_scene_url
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

  def incomplete?
    decoded_at.nil? && failed_at.nil?
  end

  def failed?
    !failed_at.nil?
  end

  # store an unescaped version of the URL that Amazon returns from direct
  # upload
  def s3_scene_url=(escaped_url)
    write_attribute(:s3_scene_url, (CGI.unescape(escaped_url) rescue nil))
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

  def http_client
    @http_client ||= Faraday.new do |faraday|
      faraday.request :json
      faraday.response :json, content_type: /\bjson$/

      faraday.adapter Faraday.default_adapter
    end
  end
end
