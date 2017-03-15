class AddUniquenessToEligibilityAccommodation < ActiveRecord::Migration[5.0]
  def change
  	add_index :eligibilities, :code, :unique => true
  	add_index :accommodations, :code, :unique => true
  end
end
