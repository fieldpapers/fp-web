# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  username               :string(32)
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

  # generate a random id (since id is not currently auto-increment)
  after_initialize :init

  # relations

  has_many :atlases,
    -> {
      order "created_at DESC"
    },
    dependent: :destroy,
    inverse_of: :creator,
    foreign_key: "user_id"

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

  def init
    self.id ||= ('a'..'z').to_a.shuffle[0,8].join
  end
end
