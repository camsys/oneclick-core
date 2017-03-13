class Service < ApplicationRecord

  ### Includes ###
  mount_uploader :logo, LogoUploader

  ### Associations ###
  has_many :itineraries
  has_and_belongs_to_many :accommodations
  has_and_belongs_to_many :eligibilities
  belongs_to :start_or_end_area, class_name: 'Region', foreign_key: :start_or_end_area_id, dependent: :destroy
  belongs_to :trip_within_area, class_name: 'Region', foreign_key: :trip_within_area_id, dependent: :destroy

  ### Validations ###
  validates_presence_of :name, :type

  ### Scopes ###
  scope :available_for, -> (trip) { self.select {|service| service.available_for?(trip)} }

  ### Class Methods ###

  def self.types
    ['Transit', 'Paratransit', 'Taxi']
  end


  ### Instance Methods ###

  def available_for?(trip)
    accommodates?(trip.user) &&
    accepts_eligibility_of?(trip.user)
  end

  # Returns true if service accommodates all of the user's needs.
  def accommodates?(user)
    return true if user.nil?
    (user.accommodations.pluck(:code) - self.accommodations.pluck(:code)).empty?
  end

  # Returns true if user meets all of the service's eligibility requirements.
  def accepts_eligibility_of?(user)
    return true if user.nil?
    (self.eligibilities.pluck(:code) - user.confirmed_eligibilities.pluck(:code)).empty?
  end


end
