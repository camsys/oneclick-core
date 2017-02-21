class AddTransitFieldsToServices < ActiveRecord::Migration[5.0]
  def change

    add_column :services, :type, :string # Allows single-table inheritance of Service types

    add_column :services, :name, :string
    add_column :services, :gtfs_agency_id, :string

  end
end
