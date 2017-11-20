module Api
  module V2
    class ConfirmationsController < Devise::ConfirmationsController

      private
      def after_confirmation_path_for(resource_name, resource)
        your_new_after_confirmation_path
      end
    
    end
  end
end