class DropAddressAndTypesFromLandmarks < ActiveRecord::Migration[5.0]
  
  def up
  	remove_column :landmarks, :types 
  	remove_column :landmarks, :address
  end

  def down
  	add_column :landmarks, :types, :text
  	add_column :landmarks, :address, :string
  end

end
