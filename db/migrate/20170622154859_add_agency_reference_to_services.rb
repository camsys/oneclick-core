class AddAgencyReferenceToServices < ActiveRecord::Migration[5.0]
  def change
    add_reference :services, :transportation_agency, index: true, foreign_key: { to_table: :agencies }
  end
end
