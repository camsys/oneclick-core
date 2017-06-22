# Agency class is a catch-all for organizations of various kinds.
# Specific agency type classes (e.g. TransportationAgency) inherit from this
# class and extend its behavior (e.g. has_many services )
class Agency < ApplicationRecord
  
  # resourcify  # This rolify call must live in the inheriting classes to work with Single-Table Inheritance
  
  AGENCY_TYPES = [
  # [ label, value(class name) ],
    ["Transportation", "TransportationAgency"],
    ["Partner", "PartnerAgency"]
  ]

  mount_uploader :logo, LogoUploader
  
  
  # All the users that have a staff role scoped to this agency
  def staff
    User.with_role(:staff, self)
  end
  
  # Add a user to this agency's staff
  def add_staff(user)
    user.add_role(:staff, self)
  end


end
