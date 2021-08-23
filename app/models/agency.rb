# Agency class is a catch-all for organizations of various kinds.
# Specific agency type classes (e.g. TransportationAgency) inherit from this
# class and extend its behavior (e.g. has_many services )
class Agency < ApplicationRecord
  
  ### INCLUDES & CONFIGS ###
  
  # mount_uploader :logo, LogoUploader  
  # resourcify  # This rolify call must live in the inheriting classes to work with Single-Table Inheritance
  include Contactable
  include Describable # has translated descriptions for each available locale
  include Logoable
  include Publishable
  
  ### SCOPES, CONSTANTS, & VALIDATIONS ###
  
  validates :name, presence: true
  validates :type, presence: true
  contact_fields email: :email, phone: :phone, url: :url
    
  scope :transportation_agencies, -> { where(type: "TransportationAgency") }
  scope :partner_agencies, -> { where(type: %w[PartnerAgency OversightAgency]) }
  
  has_many :services, foreign_key: "agency_id", dependent: :nullify
    
  AGENCY_TYPES = [
  # [ label, value(class name) ],
    ["Transportation", "TransportationAgency"],
    ["Partner", "PartnerAgency"],
    ["Oversight", "OversightAgency"]
  ]
  
  
  ### CLASS METHODS ###
  
  def self.agency_type_names
    Agency::AGENCY_TYPES.map(&:last)
  end
  
  def self.with_role(role, user)
    TransportationAgency.with_role(role, user) +
    PartnerAgency.with_role(role, user) +
    OversightAgency.with_role(role, user)
  end
  
  
  ### INSTANCE METHODS ###
  
  # All the users that have a staff role scoped to this agency
  def staff
    User.with_role(:staff, self)
  end
  
  # Add a user to this agency's staff
  def add_staff(user)
    user.add_role(:staff, self)
  end
  
  # Checks if is a TransportationAgency
  def transportation?
    self.type == "TransportationAgency"
  end

  # Checks if is a PartnerAgency
  def partner?
    self.type == "PartnerAgency"
  end

  # Checks if is an OversightAgency
  def oversight?
    self.type == "OversightAgency"
  end
  
  def to_s
    name
  end

end
