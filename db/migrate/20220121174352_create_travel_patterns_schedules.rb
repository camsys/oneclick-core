class CreateTravelPatternsSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :travel_patterns_schedules do |t|
      t.references :travel_patterns_service_schedule, index: {name: "idx_tp_schedules_to_tp_service_schedules"}
      t.integer :day
      t.integer :start_time   # time in seconds from start of day
      t.integer :end_time     # time in seconds from start of day
      t.date :calendar_date
      t.timestamps
    end
  end
end
