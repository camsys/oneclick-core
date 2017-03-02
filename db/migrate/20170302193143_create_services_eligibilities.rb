class CreateServicesEligibilities < ActiveRecord::Migration[5.0]
  def change
    create_join_table :services, :eligibilities do |t|
      t.index :service_id
      t.index :eligibility_id
    end
  end
end
