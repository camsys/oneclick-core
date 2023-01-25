class CreateFindServicesHistories < ActiveRecord::Migration[5.0]
  def change
    create_table :find_services_histories do |t|
      t.references :user, foreign_key: true, index: true
      t.inet :user_ip
      t.string :user_starting_location
      t.decimal :user_starting_lat, precision: 10, scale: 6
      t.decimal :user_starting_lng, precision: 10, scale: 6
      t.string :service_sub_sub_category
      t.integer :trip_id

      t.timestamps
    end
  end
end
