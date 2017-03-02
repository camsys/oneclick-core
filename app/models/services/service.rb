class Service < ApplicationRecord

  ### Includes ###
  mount_uploader :logo, LogoUploader

  ### Associations ###
  has_many :itineraries
  has_and_belongs_to_many :accommodations
  has_and_belongs_to_many :eligibilities

  ### Validations ###
  validates_presence_of :name, :type

  ### Scopes ###
  scope :available_for, -> (trip) { self.select {|service| service.available_for?(trip)} }

  def available_for?(trip)
    accommodates?(trip.user)
  end

  def accommodates?(user)
    (user.accommodations.pluck(:code) - accommodations.pluck(:code)).empty?
  end

  def self.types
    ['Transit', 'Paratransit', 'Taxi']
  end

end
