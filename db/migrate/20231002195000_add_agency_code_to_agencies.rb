class AddAgencyCodeToAgencies < ActiveRecord::Migration[5.0]
  def change
    add_column :agencies, :agency_code, :string
  end
end
