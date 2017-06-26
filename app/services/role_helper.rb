# Module to extend users, etc. with role helper functions
module RoleHelper
  
  ### CONSTANTS ###
  
  ROLES = [ :admin, :staff ]
  
  ############
  # ROLIFIED #
  ############
  
  # Include in User model and any other modules that implement rolify
  module Rolified
  
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
    
  end
  # ROLIFIED
  
  
  ################
  # RESOURCIFIED #
  ################
  
  # Include in Agency model and any other modules that implement resourcify
  module Resourcified
    
  end
  # RESOURCIFIED
    
  
    
end
