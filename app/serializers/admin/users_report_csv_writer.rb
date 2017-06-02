module Admin
  class UsersReportCSVWriter < CSVWriter
    columns :email, :roles, :first_name, :last_name, 
            :eligibilities, :accommodations,
            :trips_planned, :language, :created_at
    associations :accommodations, :confirmed_eligibilities, :trips, :preferred_locale
    
    def roles(user)
      user.roles.present? ? user.roles.map {|r| r.name }.join(", ") : "traveler"
    end
    
    def eligibilities(user)
      user.confirmed_eligibilities.pluck(:code).join(', ')
    end
    
    def accommodations(user)
      user.accommodations.pluck(:code).join(', ')
    end
    
    def trips_planned(user)
      user.trips.count
    end
    
    def language(user)
      user.preferred_locale && user.preferred_locale.name
    end

  end
end
