module Api
  module V1

    class UserSerializer < ActiveModel::Serializer

      attributes  :email, :first_name, :last_name,
                  :lang, :characteristics, :accommodations,
                  :preferred_modes, :preferred_trip_types

      # Returns name of preferred locale, or nil if not set
      def lang
        object.preferred_locale.nil? ? nil : object.preferred_locale.name
      end

      # Returns a list of the user's eligibilities
      def characteristics
        object.user_eligibilities.map { |ue| ue.api_hash }
      end

      # Returns a list of the user's accommodations
      def accommodations
        accs = object.accommodations.map { |acc| acc.api_hash(object.locale) }
        accs.each do |acc|
          acc[:value] = true
        end
        accs
      end

      # Returns a list of the user's preferred trip types (The old way [mode_bicycle, mode_paratransit, etc.])
      # This format is depracated after api/v1
      def preferred_modes
        #Add mode_ onto the front of the mode name.  This is done to support existing API/v1 instances.  It has been depracated
        object.preferred_trip_types.blank? ? [] : object.preferred_trip_types.map{ |m| "mode_#{m}"} 
      end

      # Returns preferred trip types (the new way [bicycle, paratransit, walk, etc.])
      def preferred_trip_types
        object.preferred_trip_types.blank? ? [] : object.preferred_trip_types
      end

    end

  end
end
