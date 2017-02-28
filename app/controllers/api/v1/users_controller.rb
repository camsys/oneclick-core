module Api
  module V1
    class UsersController < ApiController

      def profile
        hash = {first_name: @traveler.first_name, last_name: @traveler.last_name}

        ##Don't send an email address if it's just the default ecolane email
        #email = @traveler.email
        #if email.include? "@ecolane_user.com"
        #  email = ""
        #end
        #hash[:email] =  email

        #hash[:lang] = @traveler.preferred_locale
        #hash[:characteristics] = @traveler.characteristics_hash
        #hash[:accommodations] = @traveler.accommodations_hash
        #hash[:preferred_modes] = @traveler.preferred_modes_hash

        render json: hash

      end
    end
  end
end