class CreateAgencyTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :agency_types do |t|
      t.string :name
    end
  end
end
