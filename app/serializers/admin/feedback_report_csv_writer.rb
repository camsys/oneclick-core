module Admin
  class FeedbackReportCSVWriter < CSVWriter

    columns :id, :service, :feedbackable_type, :rating, :created_at, :review, :acknowledged, :email, :phone, :traveler 

    associations :user

    def traveler
      @record.user && @record.user.email
    end

    def service
      return nil if @record.feedbackable_id.nil?

      if @record.feedbackable_type == 'Service'
        my_service =  Service.find(@record.feedbackable_id)
        if my_service
          return my_service.name 
        else
          return nil 
        end
      elsif @record.feedbackable_type == 'OneclickRefernet::Service'
        my_service = OneclickRefernet::Service.find(@record.feedbackable_id)
        if my_service
          return my_service.agency_name
        else
          return nil
        end
      end

    end

  end
end
