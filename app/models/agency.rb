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
  validates :agency_type_id, presence: true
  contact_fields email: :email, phone: :phone, url: :url
    
  scope :transportation_agencies, -> { where(type: "TransportationAgency") }
  scope :partner_agencies, -> { where(type: "PartnerAgency") }
  scope :oversight_agencies, -> { where(type: "OversightAgency") }

  has_many :services, foreign_key: "agency_id", dependent: :nullify
  has_many :service_schedules
  has_many :purposes, dependent: :destroy
  # this is to help access the Agency index page, although it's a bit redundant
  has_one :agency_oversight_agency,foreign_key:"transportation_agency_id", dependent: :destroy
  belongs_to :agency_type

  AGENCY_TYPE_MAP = {
    transportation: 'TransportationAgency',
    partner: 'PartnerAgency',
    oversight: 'OversightAgency'
  }
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

  # Add an admin user to this agency
  def add_admin(user)
    user.add_role(:admin, self)
  end
  
  # Checks if is a TransportationAgency
  def transportation?
    self.type == AGENCY_TYPE_MAP[:transportation] || agency_type.name == AGENCY_TYPE_MAP[:transportation]
  end

  # Checks if is a PartnerAgency
  def partner?
    self.type == AGENCY_TYPE_MAP[:partner] || agency_type.name == AGENCY_TYPE_MAP[:partner]
  end

  # Checks if is an OversightAgency
  def oversight?
    self.type == AGENCY_TYPE_MAP[:oversight] || agency_type.name == AGENCY_TYPE_MAP[:oversight]
  end
  
  def to_s
    name
  end

end
