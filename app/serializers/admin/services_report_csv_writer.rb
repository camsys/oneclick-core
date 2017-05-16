module Admin
  class ServicesReportCSVWriter < CSVWriter
    
    columns :name, :type, :accommodations, :eligibilities, :purposes,
            :start_or_end_area, :trip_within_area
        
    def accommodations(service)
      service.accommodations.pluck(:code).join(', ')
    end
    
    def eligibilities(service)
      service.eligibilities.pluck(:code).join(', ')
    end
    
    def purposes(service)
      service.purposes.pluck(:code).join(', ')
    end
    
    def start_or_end_area(service)
      service.start_or_end_area && service.start_or_end_area.recipe.humanize
    end
    
    def trip_within_area(service)
      service.trip_within_area && service.trip_within_area.recipe.humanize
    end

  end
end
