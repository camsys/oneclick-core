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
        can :update, User, id: user.id
        return
      end
      ## General Staff Permissions ##
      can [:read, :update], Agency,     # Can read or update their own agency
        id: user.staff_agency.try(:id)
      can :read, User,                # Can manage users that are staff for the same agency
        id: user.accessible_staff.pluck(:id)
      can :manage, Service,             # Can CRUD services under their agency
        id: user.services.pluck(:id)
      can :create, Service              # Can create new services
      can :manage, Alert                # Can manage alerts
      
      ## TransportationAgency Staff Permissions ##
      if user.transportation_staff?
        can [:read, :update], Feedback, # Can read/update feedbacks related to their agency's services
          id: Feedback.about(user.services).pluck(:id)
        can [:create], User
      end
      
      ## PartnerAgency Staff Permissions ##
      if user.partner_staff?
        can [:read, :update], Feedback  # Can read/update ALL feedbacks
        can :read, :report              # Can view all reports
      end

      ## OversightAgency Staff Permissions ##
      if user.oversight_staff?
        can [:read, :update], Feedback  # Can read/update ALL feedbacks
        can :read, :report              # Can view all reports
      end
      
    end # staff
    
    ### ADMIN PERMISSIONS ###
    if user.admin?
      if user.staff_agency.nil?
        can :update, User, id: user.id
        return
      end
      can [:read, :update], Agency,     # Can read or update their own agency
          id: user.staff_agency.try(:id)
      can :manage, User,                # Can manage users that are staff for the same agency
          id: user.accessible_staff.pluck(:id)
      can :manage, Service,             # Can CRUD services under their agency
          id: user.services.pluck(:id)
      can :create, Service              # Can create new services
      can :manage, Alert
      if user.oversight_admin?                # Can manage Transportation Agencies assigned to the user's Oveersight Agency
        can :manage, Agency,
            id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id)
        can :manage, Role               # Can manage Roles

        # Oversight Admins cannot manage superusers
        cannot :manage, User,           # Cannot manage superusers
           id: User.all.superuser.pluck(:id)
        cannot :manage, Role,               # Cannot manage superuser Roles
               id: Role.find_by(name: :superuser)

        # TODO: Add the rest of the oversight admin's permissions
      end
    end

    ### SUPERUSER PERMISSIONS ###
    if user.superuser?
      can :manage, :all # Can perform all actions on all models
    end


  end
  
  def can_access_all?(model_class)
    model_class.accessible_by(self).count == model_class.count
  end
  
end
