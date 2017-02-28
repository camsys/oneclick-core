module Api
  module V1
    class UsersController < ApiController

      def profile

        hash = {email: @traveler.email, first_name: @traveler.first_name, last_name: @traveler.last_name}
        hash[:lang] = @traveler.preferred_locale.nil? ? nil : @traveler.preferred_locale.name
        #hash[:characteristics] = @traveler.characteristics_hash
        #hash[:accommodations] = @traveler.accommodations_hash
        #hash[:preferred_modes] = @traveler.preferred_modes_hash

        render json: hash

      end
    end
  end
end