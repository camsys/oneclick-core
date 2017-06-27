class Ability
  include CanCan::Ability

  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

  def initialize(user)

    ### ADMIN PERMISSIONS ###
    if user.admin?
      can :manage, :all # Can perform all actions on all models
    end
    
    
    ### STAFF PERSMISSIONS ###
    if user.staff?

      ## General Staff Permissions ##
      can [:read, :update], Agency,     # Can read or update their own agency
        id: user.agencies.pluck(:id)
      can :manage, Role,                # Can CRUD staff in their own agency
        name: "staff", 
        resource_id: user.agencies.pluck(:id)
      # can :manage, User,
      #   id: 
      
      ## TransportationAgency Staff Permissions ##
      if user.transportation_staff?
        can :manage, Service,           # Can CRUD services under their agency
          id: user.services.pluck(:id)
        can [:read, :update], Feedback, # Can read/update feedbacks related to their agency's services
          id: Feedback.about(user.services).pluck(:id)
      end
      
      ## PartnerAgency Staff Permissions ##
      if user.partner_staff?
        can [:read, :update], Feedback  # Can read/update ALL feedbacks
        can :read, :report              # Can view all reports
      end
      
    end # staff
    
    
    ### TRAVELER PERMISSIONS ###
    
    # Registered Traveler Permissions
    
    # Guest Traveler Permissions

  end
end
