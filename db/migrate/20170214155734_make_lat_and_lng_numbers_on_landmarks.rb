class MakeLatAndLngNumbersOnLandmarks < ActiveRecord::Migration[5.0]
  def change
    remove_column :landmarks, :lat, :string
    remove_column :landmarks, :lng, :string
    add_column :landmarks, :lat, :decimal, precision: 10, scale: 6
    add_column :landmarks, :lng, :decimal, precision: 10, scale: 6
  end
end
