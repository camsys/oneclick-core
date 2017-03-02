class User < ApplicationRecord

  ### Includes ###
  rolify
  acts_as_token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ### Associations ###
  has_many :trips
  has_and_belongs_to_many :accommodations
  has_many :user_eligibilities, dependent: :destroy
  has_many :eligibilities, through: :user_eligibilities
  belongs_to :preferred_locale, class_name: 'Locale', foreign_key: :preferred_locale_id

  ### Validations ###
  validates :email, presence: true
  validates :email, uniqueness: true

end
