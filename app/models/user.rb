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
  devise_mods = [:database_authenticatable, :registerable, :recoverable, :rememberable, :validatable]
  if !Rails.application.config.disable_login_confirmations
    devise_mods.push(:confirmable)
  end
  devise *devise_mods

  # callbacks

  # Content outlives its owner's account (private data remains private, so it
  # becomes unreachable). This is a temporary precaution to make sure account
  # merges don't accidentally delete content during the OSM OAuth migration.
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

end
