class Ability
  include CanCan::Ability

  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

  def initialize(user)

    ### ADMIN PERMISSIONS ###
    if user.admin?
      can :manage, :all
    end
    
    
    ### STAFF PERSMISSIONS ###
    if user.staff?

      ## General Staff Permissions ##      
      # Can read or update their own agency
      can [:read, :update], Agency, id: user.agencies.pluck(:id)
      
      # Can CRUD staff in your own agency
      # ???
      
      ## TransportationAgency Staff Permissions ##
      if user.transportation_staff?

        # Can CRUD services under their agency
        can :manage, Service, id: user.services.pluck(:id)

        # Can read/update feedbacks related to their agency's services
        can [:read, :update], Feedback, id: Feedback.concerning(user.services).pluck(:id)

      end
      
      ## PartnerAgency Staff Permissions ##
      if user.partner_staff?
      
        # Can read/update ALL feedbacks
        can [:read, :update], Feedback
        
        # Can view all reports
        can [:read], Report

      end
      
    end
    
    
    ### TRAVELER PERMISSIONS ###
    
    # Registered Traveler Permissions
    
    # Guest Traveler Permissions

  end
end
