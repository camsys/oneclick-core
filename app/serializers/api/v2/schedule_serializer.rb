module Api
  module V2
    class ScheduleSerializer < ApiSerializer

      attributes :day, :start_time, :end_time

    end
  end
end
