class User < ApplicationRecord
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  acts_as_token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :trips
  belongs_to :preferred_locale, class_name: 'Locale', foreign_key: :preferred_locale_id
  validates :email, presence: true
  validates :email, uniqueness: true

end
