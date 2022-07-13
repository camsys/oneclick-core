class AddOverrideFlagToTravelPatternServiceSchedules < ActiveRecord::Migration[5.0]
  def change
    add_column :travel_pattern_service_schedules, :overides_other_schedules, :boolean, default: false
  end
end
