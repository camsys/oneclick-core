module Admin
  class ServicesReportCSVWriter < CSVWriter
    
    columns :name, :type, :accommodations, :eligibilities, :purposes,
            :start_area, :end_area, :start_or_end_area, :trip_within_area
    associations :accommodations, :eligibilities, :purposes, 
            :start_area, :end_area, :start_or_end_area, :trip_within_area
        
    def accommodations
      @record.accommodations.pluck(:code).join(', ')
    end
    
    def eligibilities
      @record.eligibilities.pluck(:code).join(', ')
    end
    
    def purposes
      @record.purposes.pluck(:code).join(', ')
    end

    def start_area
      @record.start_area && @record.start_area.recipe.humanize
    end

    def end_area
      @record.end_area && @record.end_area.recipe.humanize
    end
    
    def start_or_end_area
      @record.start_or_end_area && @record.start_or_end_area.recipe.humanize
    end
    
    def trip_within_area
      @record.trip_within_area && @record.trip_within_area.recipe.humanize
    end

  end
end
