class Service < ApplicationRecord

  ### Includes ###
  mount_uploader :logo, LogoUploader

  ### Associations ###
  has_many :itineraries
  has_and_belongs_to_many :accommodations
  has_and_belongs_to_many :eligibilities
  belongs_to :start_or_end_area, class_name: 'Region', foreign_key: :start_or_end_area_id, dependent: :destroy
  belongs_to :trip_within_area, class_name: 'Region', foreign_key: :trip_within_area_id, dependent: :destroy
  accepts_nested_attributes_for :start_or_end_area, :trip_within_area

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
    accepts_eligibility_of?(trip.user) &&
    available_by_geography_for?(trip)
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

  # Returns true if trip falls within service coverage areas.
  def available_by_geography_for?(trip)
    available_by_start_or_end_area_for?(trip) &&
    available_by_trip_within_area_for?(trip)
  end

  # Returns true if trip origin OR destination are in start or end area, or area is not set
  def available_by_start_or_end_area_for?(trip)
    start_or_end_area.nil? ||
    start_or_end_area.contains?(trip.origin) ||
    start_or_end_area.contains?(trip.destination)
  end

  # Returns true if trip origin AND destination are in trip within area, or area is not set
  def available_by_trip_within_area_for?(trip)
    trip_within_area.nil? ||
    (trip_within_area.contains?(trip.origin) &&
    trip_within_area.contains?(trip.destination))
  end

end
