module Api
  module V1

    class TravelerProfileSerializer < ActiveModel::Serializer

      attributes :first_name

      def first_name
      end

    end

  end
end
