module Admin
  class FeedbackReportCSVWriter < CSVWriter

    columns :id, :service, :feedbackable_type, :rating, :review, :acknowledged, :email, :phone, :traveler 

    associations :user

    def traveler
      @record.user && @record.user.email
    end

    def service
      return nil if @record.feedbackable_id.nil?
    end

  end
end
