module Api
  module V2
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      # POST sign_up
      def create
        super
      end
    end
  end
end
