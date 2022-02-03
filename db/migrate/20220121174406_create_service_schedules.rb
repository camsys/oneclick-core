class CreateServiceSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :service_schedules do |t|
      t.references :service, index: true
      t.references :service_schedule_type, index: {name: "idx_service_schedules_to_service_schedule_types"}
      t.string :name
      t.string :description
      t.date :start_date
      t.date :end_date
      t.timestamps
    end
  end
end
