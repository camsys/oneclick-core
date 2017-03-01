class CreateServicesAccommodations < ActiveRecord::Migration[5.0]
  def change
    create_join_table :services, :accommodations do |t|
      t.index :service_id
      t.index :accommodation_id
    end
  end
end
