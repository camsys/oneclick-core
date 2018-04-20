module Admin
  class FeedbackReportCSVWriter < CSVWriter

    columns :id, :service, :feedbackable_type, :rating, :review, :acknowledged, :email, :phone, :traveler 

    associations :user

    def traveler
      @record.user && @record.user.email
    end

    def service
      return nil if @record.feedbackable_id.nil?

      if @record.feedbackable_type == 'Service'
        return Service.find(@record.feedbackable_id).name
      elsif @record.feedbackable_type == 'OneclickRefernet::Service'
        return OneclickRefernet::Service.find(@record.feedbackable_id).agency_name
      end

    end

  end
end
