class Service < ApplicationRecord

  ### Includes ###
  mount_uploader :logo, LogoUploader

  ### Associations ###
  has_many :itineraries
  has_and_belongs_to_many :accommodations

  ### Validations ###
  validates_presence_of :name, :type

  def self.types
    ['Transit', 'Paratransit', 'Taxi']
  end

end
