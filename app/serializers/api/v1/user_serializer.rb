module Api
  module V1

    class UserSerializer < ActiveModel::Serializer

      attributes  :email, :first_name, :last_name,
                  :lang, :characteristics, :accommodations,
                  :preferred_modes

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
        object.accommodations.map { |acc| acc.api_hash(object.locale) }
      end

      # Returns a list of the user's preferred trip types
      def preferred_modes
        object.preferred_trip_types
      end

    end

  end
end
