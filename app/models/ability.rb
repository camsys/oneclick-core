class Ability
  include CanCan::Ability

  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  # FIXME: Should refactor and standardize routes to match how Rails sets up standard routes
  # - i.e index, show, new for templates, create, update?, delete for rails controller actions
  # - Also should sort this out a bit more coherently, it's a bit of a mess at the moment
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
      can [:read, :show], Agency,     # Can read or update their own agency
        id: user.staff_agency.try(:id)
      # NOTE: :staff and :travelers are specified due to how cancan? plugs into Rails Controller actions and authorizes users
      can [:read,:staff,:travelers], User,                # Can read users that are staff for the same agency and travelers for that agency
        id: user.accessible_staff.pluck(:id)
      can :read, Service,               # Can read services under that user and services with no agency
        id: user.services.pluck(:id).concat(Service.no_agency.pluck(:id))
      can [:read, :edit], Alert                # Can manage alerts
      can [:read,:edit], Eligibility
      can [:read,:edit], Accommodation
      #can [:read, :edit], FundingSource
          #  agency_id: user.staff_agency.try(:id)
      can [:read,:edit], Purpose
      can :read, GeographyRecord
      can [:read, :edit], Landmark
      can [:read], LandmarkSet

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

        # Can read users that are staff for the same agency and travelers for that agency
        can [:edit,:staff,:travelers], User,
            id: user.accessible_staff.pluck(:id).concat(user.travelers_for_current_agency.pluck(:id))

        # Can show own oversight agency and overseen transportation agencies
        can :show, Agency,
            id: user.staff_agency.agency_oversight_agency.map{|aoa| aoa.transportation_agency.id}.concat([user.staff_agency.id])
        can [:read, :update], Feedback  # Can read/update ALL feedbacks

        #can [:show], FundingSource,
        #    agency_id: user.staff_agency.agency_oversight_agency.map{|aoa| aoa.transportation_agency.id}.concat([user.staff_agency.id])

        # Can access services associated with own oversight agency, and those with no oversight agency(i.e taxi services)
        can :read, Service,
            id: user.get_services_for_oversight.pluck(:id).concat(Service.no_agencies_assigned.pluck(:id))
        can :change_agency, User,
            id: user.id
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
      can :manage, CustomGeography
      can :manage, Eligibility
      can :manage, Accommodation
      #can :manage, Purpose
      can :manage, Feedback
      can :manage, Landmark
      can [:show, :update], Agency,     # Can read or update their own agency
          id: user.staff_agency.try(:id)
      #can [:show, :update], FundingSource,
      #    agency_id: user.staff_agency.try(:id)

      # Can manage users that are staff for the same agency or unaffiliated staff and travelers for that agency
      can :manage, User,
          id: user.accessible_staff.pluck(:id).concat(user.get_travelers_for_staff_user&.pluck(:id) || [])

      # Can CRUD services with no agency
      can :manage, Service,
          id: Service.no_agency.pluck(:id)
      can :create, Service              # Can create new services
      can :manage, Alert
      can :read, :report         # Can view all reports
      # Mapping related permissions
      can :manage, GeographyRecord      # Can create Geography records
      can :manage, Role,                # Can manage roles for current agency
          resource_id: user.staff_agency.id
      # Admins cannot manage superusers
      cannot :manage, User,           # Cannot manage superusers
              id: User.all.superuser.pluck(:id)
      cannot :manage, Role,               # Cannot manage superuser Roles
              id: Role.find_by(name: :superuser)

      # Transportation Admin Permissions
      if user.transportation_admin?

        can :manage, TravelPattern, agency_id: user.staff_agency.try(:id)
        can :manage, LandmarkSet, agency_id: user.staff_agency.try(:id)
        can :manage, OdZone, agency_id: user.staff_agency.try(:id)
        can :manage, ServiceSchedule, agency_id: user.staff_agency.try(:id)
        Rails.logger.info "Transportation Admin Permissions Set for #{user.id}: Can manage ServiceSchedule with agency_id #{user.staff_agency.try(:id)}"
        can :manage, ServiceSubSchedule, service_schedule: { agency_id: user.staff_agency.try(:id) }
        can :manage, Purpose, agency_id: user.staff_agency.try(:id)
        can :manage, FundingSource, agency_id: user.staff_agency.try(:id)
        can :manage, BookingWindow, agency_id: user.staff_agency.try(:id)
        can :manage, GeographyRecord, agency_id: user.staff_agency.try(:id)

        # Can access services associated with an oversight agency, and those with no oversight agency
        can :manage, Service,
            id: user.staff_agency.services.pluck(:id).concat(Service.no_agencies_assigned.pluck(:id)) # Can access services associated with the users transportation agency
      end

      # Oversight Admin Permissions
      if false && user.oversight_admin?                # Can manage Transportation Agencies assigned to the user's Oveersight Agency
        can :manage, TravelPattern,
            agency_id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
        can :manage, Agency,
            id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
        can :create, Agency
        can :manage, LandmarkSet,
            agency_id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
        can :manage, OdZone,
            agency_id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
        can :manage, ServiceSchedule,
            agency_id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
        can :manage, Purpose,
            agency_id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
        can :manage, FundingSource,
            agency_id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
        can :manage, BookingWindow,
            agency_id: user.staff_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.staff_agency.id])
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
    if user.superuser? || user.oversight_admin?
      can :manage, :all # Can perform all actions on all models
    end


  end
  
  def can_access_all?(model_class)
    model_class.accessible_by(self).count == model_class.count
  end
end
