module Admin
  class RequestsReportCSVWriter < CSVWriter
    
    columns :date, 
            :controller, 
            :action, 
            :status_code, 
            :auth_email, 
            :duration, 
            :params
            
    def date
      @record.created_at
    end

  end
end
