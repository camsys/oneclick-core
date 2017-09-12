module Api
  module V2
    class UserAlertSerializer < ActiveModel::Serializer
		  
		  attributes :id, :subject, :message
    
    end
  end
end

