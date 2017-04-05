class AddFareFieldsToServicesTable < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :fare_structure, :string
    add_column :services, :fare_details, :text
  end
end
