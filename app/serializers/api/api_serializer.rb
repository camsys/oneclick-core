module Api

  # Parent Class for API Serializers
  class ApiSerializer < ActiveModel::Serializer

    # Pulls the locale out of the scope hash if present (should be set in controller before_action)
    def locale
      (scope || {})[:locale]
    end

  end
end
