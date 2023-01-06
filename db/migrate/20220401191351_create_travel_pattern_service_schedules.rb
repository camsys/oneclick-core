class CreateTravelPatternServiceSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :travel_pattern_service_schedules do |t|
      t.references :travel_pattern
      t.references :service_schedule
      t.integer :priority
      t.timestamps
    end
  end
end
