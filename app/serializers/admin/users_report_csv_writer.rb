module Admin
  class UsersReportCSVWriter < CSVWriter
    columns :email, :roles, :first_name, :last_name, 
            :eligibilities, :accommodations,
            :trips_planned, :language, :county, :paratransit_id, :created_at
    associations :accommodations, :confirmed_eligibilities, :trips, :preferred_locale
    
    def roles
      @record.roles.present? ? @record.roles.map {|r| r.name }.join(", ") : "traveler"
    end
    
    def eligibilities
      @record.confirmed_eligibilities.pluck(:code).join(', ')
    end
    
    def accommodations
      @record.accommodations.pluck(:code).join(', ')
    end
    
    def trips_planned
      @record.trips.count
    end
    
    def language
      @record.preferred_locale && @record.preferred_locale.name
    end

  end
end
