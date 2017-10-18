module Api
  module V2
    class ScheduleSerializer < ActiveModel::Serializer

      attributes :day, :start_time, :end_time

    end
  end
end
