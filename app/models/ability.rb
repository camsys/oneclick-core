class Ability
  include CanCan::Ability

  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

  def initialize(user)
    
    ### TRAVELER PERMISSIONS ###
    
    # Registered Traveler Permissions
    if user.traveler?
      cannot :manage, :all # Can't do anything in the admin pages
    end
    
    # Guest Traveler Permissions
    if user.guest?
      cannot :manage, :all # Can't do anything in the admin pages
    end
    
    
    ### STAFF PERMISSIONS ###
    if user.staff?
      # If a staff user has no agency, then they can only update themselves
      if user.staff_agency.nil?
        cannot :manage, :all
        can :update, User, id: user.id
        return
      end

      ## General Staff Permissions ##
      can [:read, :update], Agency,     # Can read or update their own agency
        id: user.staff_agency.try(:id)
      # NOTE: :staff and :travelers are specified due to how cancan? plugs into Rails Controller actions and authorizes users
      can [:read,:staff,:travelers], User,                # Can read users that are staff for the same agency and travelers for that agency
        id: user.accessible_staff.pluck(:id)
      can :read, Service,               # Can read services under that user and services with no agency
        id: user.services.pluck(:id).concat(Service.no_agency.pluck(:id))
      can :read, Alert                # Can manage alerts
      can :read, :report         # Can read reports
      can :read, Eligibility
      can :read, Accommodation
      can :read, Purpose
      can :read, GeographyRecord
      can :read, Landmark


      ## TransportationAgency Staff Permissions ##
      if user.transportation_staff?
        can [:read,:staff,:travelers], User,                # Can read users that are staff for the same agency and travelers for that agency
            id: user.accessible_staff.pluck(:id).concat(user.travelers_for_staff_agency.pluck(:id))
        can [:read, :update], Feedback, # Can read/update feedbacks related to their agency's services
          id: Feedback.about(user.services).pluck(:id)
        can :create, User
      end
      
      ## PartnerAgency Staff Permissions ##
      if user.partner_staff?
        can [:read, :update], Feedback  # Can read/update ALL feedbacks
        can :read, :report              # Can view all reports
      end

      ## OversightAgency Staff Permissions ##
      if user.oversight_staff?
        can [:read,:staff,:travelers], User,                # Can read users that are staff for the same agency and travelers for that agency
            id: user.accessible_staff.pluck(:id).concat(user.travelers_for_current_agency.pluck(:id))

        can [:read, :update], Feedback  # Can read/update ALL feedbacks
        can :read, Agency
        can :read, Service,
            id: user.get_services_for_oversight.pluck(:id).concat(Service.no_agencies_assigned.pluck(:id)) # Can access services associated with an oversight agency, and those with no oversight agency
      end
      # staff users can update themselves
      can :update, User,
          id: user.id
    end # staff
    
    ### ADMIN PERMISSIONS ###
    if user.admin?
      if user.staff_agency.nil?
        cannot :manage, :all
        can :update, User, id: user.id
        return
      end

      # General affiliated admin permissions
      can :manage, Eligibility
      can :manage, Accommodation
      can :manage, Purpose
      can :manage, Feedback
      can :manage, Landmark
      can [:read, :update], Agency,     # Can read or update their own agency
          id: user.staff_agency.try(:id)
      can :manage, User,                # Can manage users that are staff for the same agency or unaffiliated staff and travelers for that agency
          id: user.accessible_staff.pluck(:id).concat(User.staff_for_none.pluck(:id),User.admin_for_none.pluck(:id),user.get_travelers_for_staff_user.pluck(:id))
      can :manage, Service,             # Can CRUD services with no agency
          id: Service.no_agency.pluck(:id)
      can :create, Service              # Can create new services
      can :manage, Alert
      can :read, :report         # Can view all reports
      # Mapping related permissions
      can :create, GeographyRecord      # Can create Geography records
      can :manage, Role,                # Can manage roles for current agency
          resource_id: user.staff_agency.id

      # Transportation Admin Permissions
      if user.transportation_admin?
        can :manage, Service,
            id: user.staff_agency.services.pluck(:id).concat(Service.no_agencies_assigned.pluck(:id)) # Can access services associated with the users transportation agency
      end

      # Oversight Admin Permissions
      if user.oversight_admin?                # Can manage Transportation Agencies assigned to the user's Oveersight Agency
        can :manage, Agency,
            id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id)
        can :create, Agency
        can :manage, Service,
          id: user.get_services_for_oversight.pluck(:id).concat(Service.no_agencies_assigned.pluck(:id)) # Can access services associated with an oversight agency, and those with no oversight agency
        can :manage, Role               # Can manage Roles
        # Mapping related permissions
        can :manage, GeographyRecord    # Can manage geography records

        # Oversight Admins cannot manage superusers
        cannot :manage, User,           # Cannot manage superusers
           id: User.all.superuser.pluck(:id)
        cannot :manage, Role,               # Cannot manage superuser Roles
               id: Role.find_by(name: :superuser)
      end
    end # end admin

    ### SUPERUSER PERMISSIONS ###
    if user.superuser?
      can :manage, :all # Can perform all actions on all models
    end


  end
  
  def can_access_all?(model_class)
    model_class.accessible_by(self).count == model_class.count
  end
end
