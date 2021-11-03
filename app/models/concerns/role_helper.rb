# Module to extend users, etc. with role helper functions
module RoleHelper

  PERMISSIBLE_CREATES = {
    admin: [:admin, :staff],
    superuser: Role::ROLES
  }
  ### SCOPES & CLASS METHODS ###

  def self.included(base)

    base.extend(ClassMethods)

    # SCOPES
    # NOTE: the with_(any_)role method in Rolify <v6.0 is buggy
    # ... and does not work the way it should work
    # see: https://github.com/RolifyCommunity/rolify/issues/362 and the v6.0 release notes

    # NOTE: the :any_role scope is probably using Rolify wrong, but seems to work so not touching it
    base.scope :any_role, -> do
      base.querify(base.with_any_role(
        {name: :admin, resource: :any},
        {name: :staff, resource: :any},
        {name: :superuser, resource: :any},
      ))
    end
    # SCOPES FOR LOOKING UP STAFF
    base.scope :staff_for_none, -> { base.with_role_for_instance(:staff, nil) }
    base.scope :staff, -> { base.querify(base.with_role_for_instances_or_none(:staff, Agency.all)) }
    base.scope :staff_for, -> (agency) { base.with_role_for_instance(:staff, agency) }
    base.scope :staff_for_any, -> (agencies) { base.with_role_for_instances_or_none(:staff, agencies) }

    # SCOPES FOR LOOKING UP ADMINS
    base.scope :admin_for_none, -> { base.with_role(:admin, nil) }
    base.scope :admins, -> { base.querify(base.with_role_for_instances_or_none(:admin, Agency.all)) }
    base.scope :admin_for, -> (agency) { base.with_role_for_instance(:admin, agency) }
    base.scope :admin_for_any, -> (agencies) { base.with_role_for_instances_or_none(:admin, agencies) }

    # SCOPES FOR LOOKING UP BOTH STAFF AND ADMIN
    base.scope :any_staff_admin_for_agencies, -> (agencies) { base.with_roles_for_instances([:staff, :admin], agencies) }
    base.scope :any_staff_admin_for_agency, -> (agency) { base.with_roles_for_instance([:staff, :admin], agency) }
    base.scope :any_staff_admin_for_none, -> { base.with_roles_for_instance_or_none([:staff,:admin],nil) }

    # GENERAL USER ROLE SCOPES
    base.scope :superuser, -> { base.querify(base.with_role(:superuser, :any)) }
    base.scope :travelers, -> { base.where.not(id: base.any_role.pluck(:id)) }
    base.scope :guests, -> { base.travelers.where(GuestUserHelper.new.query_str) }
    base.scope :registered, -> { base.where.not(GuestUserHelper.new.query_str) }
    base.scope :registered_travelers, -> { base.travelers.registered }
    base.scope :except_user, -> (user) { where.not(id: user.id) }
    base.scope :partner_staff, -> { base.staff_for_any(Agency.partner_agencies) }
    base.scope :transportation_staff, -> { base.staff_for_any(Agency.transportation_agencies) }


    # ASSOCIATIONS
    base.has_many :transportation_agencies,
      through: :roles,
      source: :resource,
      source_type: "TransportationAgency"
    base.has_many :partner_agencies,
      through: :roles,
      source: :resource,
      source_type: "PartnerAgency"
    base.has_many :oversight_agencies,
      through: :roles,
      source: :resource,
      source_type: "OversightAgency"

    base.validate :must_have_a_role, if: :role_required?
    
  end

  # CLASS METHOD DEFINITIONS
  module ClassMethods
  end

  ####################
  # INSTANCE METHODS #
  ####################


  ### CHECKING USER ROLES ###

  # Does the use have either an admin or a staff role?
  def admin_or_staff?
    admin? || staff?
  end

  # Check to see if the user is an Admin, any scope
  def admin?
    has_role?(:admin) || has_role?(:admin, :any)
  end

  def superuser?
    has_role?(:superuser, :any)
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

  # Check to see if the user is a OversightAgency staff
  def oversight_staff?
    staff? && agencies.any? { |a| a.oversight? }
  end

  # Check to see if the user is a TransportationAgency admin
  def transportation_admin?
    admin? && agencies.any? { |a| a.transportation? }
  end

  # Check to see if the user is a PartnerAgency admin
  def partner_admin?
    admin? && agencies.any? { |a| a.partner? }
  end

  # Check to see if the user is a OversightAgency admin
  def oversight_admin?
    admin? && agencies.any? { |a| a.oversight? }
  end

  def unaffiliated_user?
    (admin? || staff?) && roles.length == 1 && roles.first.resource.nil?
  end

  # Check to see if the user is a traveler (i.e. has no roles)
  def traveler?
    !admin_or_staff?
  end


  ### ASSOCIATIONS VIA USER ROLES ###

  # Returns the agencies that the user is staff for
  def agencies
    Agency.where(id: transportation_agencies.pluck(:id) + oversight_agencies.pluck(:id))
  end

  # Returns the last of the user's staffing agencies (of which there are hopefully just one)
  def staff_agency
    agencies.last
  end

  # Returns a collection of the user's transportation agency's services
  def services
    Service.where(agency: agencies)
  end

  # Returns the agencies that the user may manage
  def accessible_agencies
    Agency.accessible_by(Ability.new(self))
  end

  def accessible_transportation_agencies
    TransportationAgency.accessible_by(Ability.new(self))
  end

  def accessible_oversight_agencies
    OversightAgency.accessible_by(Ability.new(self))
  end

  # Returns a list of users who are staff for any of the agencies this user is staff for
  def fellow_staff
    User.staff_for_any(agencies)
  end

  # Returns a list of the staff that the user has permissions to access
  def accessible_staff
    return User.any_role if admin?
    return fellow_staff if staff?
    return User.none
  end

  def currently_oversight?
    self.current_agency&.oversight?
  end

  def currently_transportation?
    self.current_agency&.transportation?
  end

  def any_users_for_staff_agency
    User.any_staff_admin_for_agency(self.staff_agency)
  end

  def any_users_for_current_agency
    User.any_staff_admin_for_agency(self.current_agency)
  end

  def travelers_for_none
    User.querify(User.travelers.select{|u| u.traveler_transit_agency&.transportation_agency.nil? || u.booking_profiles.length == 0})
  end

  def travelers_for_agency(agencies)
    # Search for travelers not associated with the input agencies ids
    agency_travelers_id = TravelerTransitAgency.where.not(transportation_agency_id: agencies)
    # Return travelers associated with the input agency and also with no agency
    uu = User.travelers.where.not(id: agency_travelers_id.pluck(:user_id))
    User.querify(uu.select{|u| u.traveler_transit_agency&.transportation_agency&.present?})
  end

  def travelers_for_staff_agency
    ta = TransportationAgency.find(self.staff_agency.id)
    travelers_for_agency(ta)
  end

  def travelers_for_current_agency
    ag = Agency.find_by(id:self.current_agency&.id)
    travelers_for_agency(ag)
  end

  ### MODIFYING USER ROLES ###

  # Replaces the user's staff agency role with the passed agency
  # wraps in a transaction so changes will be rolled back on error
  def set_staff_role(agency)
    if agency && staff_agency != agency
      self.remove_role(:staff)
      self.add_role(:staff, agency)
      r = self.roles.last
    elsif agency.nil?
      self.remove_role(:staff)
      r = self.roles.last
    end
  end

  # General set role method
  # - just like set_staff_role, should be wrapped in a transaction so changes can be rolledback
  def set_role(role, agency)
    if !agency && !role
      raise "Expecting values for role and agency"
    end
    if role == "superuser"
      self.add_role(role)
    elsif agency == ""|| agency.nil?
      self.add_role(role)
    elsif staff_agency.nil?
      self.add_role(role,agency)
    elsif agency
      self.remove_role(self.roles.last.name.to_sym)
      self.add_role(role,agency)
    end
  end


  # Adds or removes the user's admin permissions based on passed boolean
  # wraps in a transaction so changes will be rolled back on error
  def set_admin(bool)
    bool ? self.add_role(:admin) : self.remove_role(:admin)
  end


  ### VALIDATIONS ###

  def require_role
    @role_required = true
  end

  # Checks to see if a role is required for validation
  def role_required?
    @role_required || false
  end

  # Validates that the user has at least one role
  def must_have_a_role
    errors.add(:roles, "Must have a staff or admin role") unless admin_or_staff?
  end

  ### GENERAL ADMIN CONSOLE BASED HELPERS ###
  def get_transportation_agencies_for_user
    if self.superuser?
      TransportationAgency.all
    elsif self.currently_oversight? || (self.current_agency.nil? && self.staff_agency.oversight?)
      self.accessible_transportation_agencies
    elsif self.currently_transportation?
      Agency.querify([self.current_agency])
    elsif self.transportation_admin? || self.transportation_staff?
      Agency.querify([self.staff_agency])
    else
      nil
    end
  end

  def get_admin_staff_for_staff_user
    if self.superuser?
      User.staff
    elsif self.transportation_admin? || self.transportation_staff?
      self.any_users_for_staff_agency
    elsif self.currently_oversight? || self.currently_transportation?
      self.any_users_for_current_agency
    elsif self.current_agency.nil?
      User.any_staff_admin_for_none
    else
      []
    end
  end

  def get_travelers_for_staff_user
    if self.superuser?
      User.travelers
    elsif self.transportation_admin? || self.transportation_staff?
      self.travelers_for_staff_agency
    elsif self.currently_oversight? || self.currently_transportation?
      self.travelers_for_current_agency
    elsif self.current_agency.nil?
      self.travelers_for_none
    else
      nil
    end
  end

  def get_trips_for_staff_user
    # Conditional statement flow:
    # If current user is a traveler => return nil
    # If current user is a superuser => return all Trips
    # If current user is a transportation agency staff => return Trips associated with the agency
    # If current user is viewing as oversight staff => return Trips associated with all agencies under the oversight agency
    # If current user is viewing as transportation agency staff => return Trips associated with the current transportation agency
    # If the current user is viewing all unaffiliated trips and is oversight staff => return Trips associated with no tranpsortation agency
    if self.traveler? || self.staff_agency.nil?
      nil
    elsif self.superuser?
      Trip.all
    elsif self.transportation_admin? || self.transportation_staff?
      Trip.with_transportation_agency(self.staff_agency.id)
    elsif self.currently_oversight?
      tas = AgencyOversightAgency.where(oversight_agency_id: self.staff_agency.id).pluck(:transportation_agency_id)
      Trip.with_transportation_agency(tas)
    elsif self.currently_transportation?
       Trip.with_transportation_agency(self.current_agency.id)
    elsif self.staff_agency.oversight? && self.current_agency.nil?
      Trip.with_no_transportation_agency
      # Fallback just in case an edge case is missed
    else
      nil
    end
  end

  def get_services_for_staff
    if self.superuser?
      Service.all
    elsif self.transportation_admin? || self.transportation_staff?
      self.services
    elsif self.currently_transportation?
      Service.where(agency: self.current_agency)
    elsif self.currently_oversight?
      Service.joins(:service_oversight_agency).where('service_oversight_agencies.oversight_agency_id': self.current_agency)
    else
      nil
    end
  end

  def get_services_for_oversight
    tas = Agency.left_joins(:agency_oversight_agency)
                .where('agency_oversight_agencies.oversight_agency_id': self.staff_agency)
                .select('agency_oversight_agencies.transportation_agency_id').pluck(:transportation_agency_id)
    Service.left_joins(:service_oversight_agency)
           .where('service_oversight_agencies.oversight_agency_id = ? OR services.agency_id in (?)', self.current_agency&.id, tas)
  end

end
