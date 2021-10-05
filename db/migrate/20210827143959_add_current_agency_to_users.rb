class AddCurrentAgencyToUsers < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :current_agency, index: true
    add_foreign_key :users, :agencies, column: :current_agency_id
  end
end
