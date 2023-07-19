class AddUniquenessIndexesToJoinTables < ActiveRecord::Migration[5.0]
  def change
    add_index :accommodations_users, [:user_id, :accommodation_id], unique: true
    add_index :accommodations_services, [:service_id, :accommodation_id], unique: true, name: 'idx_services_accommodations_on_service_id_and_accommodation_id'
    add_index :eligibilities_services, [:service_id, :eligibility_id], unique: true
    add_index :purposes_services, [:service_id, :purpose_id], unique: true
  end
end
