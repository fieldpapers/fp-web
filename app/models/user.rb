# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key, auto_increment
#  username               :string(255)
#  legacy_password        :string(40)
#  email                  :string(255)
#  encrypted_password     :string(255)      default(""), not null
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  updated_at             :datetime
#  created_at             :datetime
#  osm_id                 :bigint
#

class User < ActiveRecord::Base
  # Virtual attribute for authenticating by either username or email
  # This is in addition to a real persisted field like 'username'
  attr_accessor :login

  # Password login (database_authenticatable, recoverable, rememberable) is only
  # for legacy accounts that haven't been connected to OSM yet.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable,
    :omniauthable, omniauth_providers: [:osm]

  # callbacks

  # Public atlases and snapshots are disowned when an account is deleted.
  # (delete_account! runs first and deletes private content)
  before_destroy do
    Atlas.unscoped.where(user_id: id).update_all(user_id: nil)
    Snapshot.unscoped.where(user_id: id).update_all(user_id: nil)
  end

  # validations

  # Usernames mirror OSM display names, which can collide with legacy usernames
  # (and with stale names of users who renamed on OSM), so they are not unique.
  validates :username, presence: true

  # class methods

  # override to support logins with both username and email. Only accounts not
  # yet connected to OSM can log in with a password; their usernames are unique
  # among the other legacy accounts (but not necessarily among all accounts).
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    users = where(osm_id: nil)
    if login = conditions.delete(:login)
      users.where(conditions.to_h).where(["LOWER(username) = :value OR LOWER(email) = :value", { :value => login.downcase }]).first
    else
      users.where(conditions.to_h).first
    end
  end

  # instance methods

  # OSM users have no email or password
  def email_required?
    osm_id.nil?
  end

  def password_required?
    osm_id.nil? && super
  end

  # Whether password is this legacy account's password, which may be bcrypt
  # or (pre-2015) unsalted SHA1. Password login upgrades SHA1 hashes (see
  # Devise::Strategies::Legacy); this doesn't.
  def legacy_password_valid?(password)
    if legacy_password.present?
      legacy_password == Digest::SHA1.hexdigest(password)
    else
      valid_password?(password)
    end
  end

  # Merge another user account into this one: adopt its atlases and snapshots,
  # take the older of the two creation times, then delete the other account.
  def absorb!(other)
    transaction do
      Atlas.unscoped.where(user_id: other.id).update_all(user_id: id)
      Snapshot.unscoped.where(user_id: other.id).update_all(user_id: id)
      update_columns(created_at: [created_at, other.created_at].compact.min)
      other.delete
    end
  end

  # Deletes this account along with its private atlases and snapshots. Public
  # ones are kept (they get disowned in before_destroy).
  #
  # TODO: also delete the deleted atlases' and snapshots' files (atlas and
  # page PDFs, which are public-read in S3, and snapshot GeoTIFFs)
  def delete_account!
    transaction do
      others = Snapshot.unscoped.where("user_id IS DISTINCT FROM ?", id)
      shared = Page.where(id: others.select(:page_id)).select(:atlas_id)
      atlases = Atlas.unscoped.where(user_id: id, private: true).where.not(id: shared)
      pages = Page.where(atlas_id: atlases.select(:id))

      mine = Snapshot.unscoped.where(user_id: id)
      mine.where(private: true).or(mine.where(page_id: pages.select(:id))).destroy_all
      atlases.destroy_all
      destroy!
    end
  end

end
