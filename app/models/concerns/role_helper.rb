# Module to extend users, etc. with role helper functions
module RoleHelper

  ### SCOPES & CLASS METHODS ###

  def self.included(base)

    base.extend(ClassMethods)

    # SCOPES
    base.scope :any_role, -> do
      base.querify(base.with_any_role(
        {name: :admin, resource: :any},
        {name: :staff, resource: :any}
      ))
    end
    base.scope :staff_for, -> (agency) { base.with_role(:staff, agency) }
    base.scope :staff_for_any, -> (agencies) do # Returns staff for any of the agencies in the passed collection
      base.querify( base.with_any_role(*agencies.map{|ag| { :name => :staff, :resource => ag }}) )
    end
    base.scope :admins, -> { base.querify(base.with_role(:admin, :any)) }
    base.scope :staff, -> { base.querify(base.with_role(:staff, :any)) }
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
    !admin_or_staff?
  end


  ### ASSOCIATIONS VIA USER ROLES ###

  # Returns the agencies that the user is staff for
  def agencies
    Agency.where(id: transportation_agencies.pluck(:id) + partner_agencies.pluck(:id))
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


end
