class CreateTravelPatternsServiceSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :travel_patterns_service_schedules do |t|
      t.references :service, index: true
      t.references :travel_patterns_service_schedule_type, index: {name: "idx_tp_service_schedules_to_tp_service_schedule_types"}
      t.string :name
      t.string :description
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
