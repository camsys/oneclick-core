# Module to extend users, etc. with role helper functions
module RoleHelper
  
  ### SCOPES & CLASS METHODS ###
  
  def self.included(base)
    
    base.extend(ClassMethods)
    
    # SCOPES
    base.scope :admins, -> { base.with_role(:admin, :any) }    
    base.scope :any_role, -> do
      base.with_any_role({name: :admin, resource: :any}, {name: :staff, resource: :any})
    end
    base.scope :guests, -> { base.travelers.where(GuestUserHelper.new.query_str) }
    base.scope :registered, -> { base.where.not(GuestUserHelper.new.query_str) }
    base.scope :registered_travelers, -> { base.travelers.registered }
    base.scope :staff, -> { base.with_role(:staff, :any) }
    base.scope :travelers, -> { base.where.not(id: base.any_role.pluck(:id)) }
    
    # ASSOCIATIONS
    base.has_many :transportation_agencies, 
      through: :roles, 
      source: :resource, 
      source_type: "TransportationAgency"
    base.has_many :partner_agencies,
      through: :roles,
      source: :resource,
      source_type: "PartnerAgency"
      
    # base.accepts_nested_attributes_for :roles, allow_destroy: true
    
  end

  # CLASS METHOD DEFINITIONS
  module ClassMethods
  end
  
  
  ### INSTANCE METHODS ###
  
  def has_no_roles?
    !has_any_role?
  end
    
  # Check to see if the user is an Admin, any scope
  def admin?
    has_role? :admin, :any
  end

  # Check to see if the user is a guest (i.e. not registered)
  def guest?
    GuestUserHelper.new.is_guest_email?(email)
  end
  
  # Check to see if the user registered (i.e. not a guest)
  def registered?
    !guest?
  end
  
  # Check to see if the user is a registered traveler (i.e. not a guest, no roles)
  def registered_traveler?
    registered? && traveler?
  end
  
  # Check to see if the user is a staff, any scope
  def staff?
    has_role? :staff, :any
  end
  
  # Check to see if the user is a TransportationAgency staff
  def transportation_staff?
    staff? && agencies.any? { |a| a.transportation? }
  end
  
  # Check to see if the user is a PartnerAgency staff
  def partner_staff?
    staff? && agencies.any? { |a| a.partner? }
  end
  
  # Check to see if the user is a traveler (i.e. has no roles)
  def traveler?
    has_no_roles?
  end
  
  # Returns the agencies that the user is staff for
  def agencies
    transportation_agencies + partner_agencies
  end
  
  # Returns a collection of the user's transportation agency's services
  def services
    Service.where(transportation_agency: transportation_agencies)
  end
  
  # Replaces all roles with the passed roles, wrapping it in a transaction
  # and rolling back to the original roles if there's an error
  def update_roles(roles)
    self.class.transaction do
      self.roles.destroy_all
      self.add_roles(roles)
    end
  end
  
  # Takes a collection of roles objects or an array of roles attributes hashes,
  # and adds those roles to the rolified object
  def add_roles(roles)
    roles.each do |role|
      self.add_role(role[:name], find_resource(role[:resource_type], role[:resource_id]))
    end
  end
  
  def find_resource(type, id)
    if type.present? && id.present?
      resource_id = id.to_i
      base_resource_class = type.constantize.base_class
      return base_resource_class.find(resource_id)
    else
      return nil
    end
  end
    
end
