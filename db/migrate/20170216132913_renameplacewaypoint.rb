class Renameplacewaypoint < ActiveRecord::Migration[5.0]
  def change
  	rename_table :places, :waypoints
  end
end
