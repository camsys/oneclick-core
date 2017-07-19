class ModifyAgencyReferenceToServices < ActiveRecord::Migration[5.0]
  def change
    remove_reference :services, :agency, index: true, foreign_key: { to_table: :agencies }
    add_reference :services, :agency, index: true, foreign_key: true
  end
end
