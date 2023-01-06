class CreateServiceSubSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :service_sub_schedules do |t|
      t.references :service_schedule, index: {name: "idx_service_sub_schedules_to_service_schedules"}
      t.integer :day
      t.integer :start_time   # time in seconds from start of day
      t.integer :end_time     # time in seconds from start of day
      t.date :calendar_date
      t.timestamps
    end
  end
end
