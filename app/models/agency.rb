# Agency class is a catch-all for organizations of various kinds.
# Specific agency type classes (e.g. TransportationAgency) inherit from this
# class and extend its behavior (e.g. has_many services )
class Agency < ApplicationRecord
  
  ### INCLUDES & CONFIGS ###
  
  mount_uploader :logo, LogoUploader  
  # resourcify  # This rolify call must live in the inheriting classes to work with Single-Table Inheritance
  
  
  ### SCOPES, CLASS METHODS, & CONSTANTS ###
  
  scope :transportation_agencies, -> { where(type: "TransportationAgency") }
  scope :partner_agencies, -> { where(type: "PartnerAgency") }
  
  AGENCY_TYPES = [
  # [ label, value(class name) ],
    ["Transportation", "TransportationAgency"],
    ["Partner", "PartnerAgency"]
  ]
  
  def self.with_role(role, user)
    TransportationAgency.with_role(role, user) +
    PartnerAgency.with_role(role, user)
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

end
