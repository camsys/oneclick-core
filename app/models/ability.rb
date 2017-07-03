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
    
    
    ### STAFF PERSMISSIONS ###
    if user.staff?

      ## General Staff Permissions ##
      can [:read, :update], Agency,     # Can read or update their own agency
        id: user.staff_agency.try(:id)
      can :manage, User,                # Can manage users that are staff for the same agency
        id: user.accessible_staff.pluck(:id)
      can :manage, Service,             # Can CRUD services under their agency
        id: user.services.pluck(:id)
      can :create, Service              # Can create new services
      
      ## TransportationAgency Staff Permissions ##
      if user.transportation_staff?
        can [:read, :update], Feedback, # Can read/update feedbacks related to their agency's services
          id: Feedback.about(user.services).pluck(:id)
      end
      
      ## PartnerAgency Staff Permissions ##
      if user.partner_staff?
        can [:read, :update], Feedback  # Can read/update ALL feedbacks
        can :read, :report              # Can view all reports
      end
      
    end # staff
    
    ### ADMIN PERMISSIONS ###
    if user.admin?
      can :manage, :all # Can perform all actions on all models
    end


  end
  
  def can_access_all?(model_class)
    model_class.accessible_by(self).count == model_class.count
  end
  
end
