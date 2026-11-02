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

  # devise configuration (authentication)
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  # callbacks

  # Public atlases and snapshots are disowned when an account is deleted.
  # (delete_account! runs first and deletes private content)
  before_destroy do
    Atlas.unscoped.where(user_id: id).update_all(user_id: nil)
    Snapshot.unscoped.where(user_id: id).update_all(user_id: nil)
  end

  # validations

  validates :username,
    presence: true,
    uniqueness: {
      case_sensitive: false
    }

  # class methods

  # override to support logins with both username and email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["LOWER(username) = :value OR LOWER(email) = :value", { :value => login.downcase }]).first
    else
      where(conditions.to_h).first
    end
  end

  # instance methods

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
