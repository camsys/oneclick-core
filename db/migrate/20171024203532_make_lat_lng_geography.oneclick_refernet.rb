# This migration comes from oneclick_refernet (originally 20171024203305)
class MakeLatLngGeography < ActiveRecord::Migration[5.0]
  def change
    add_column :oneclick_refernet_services, :latlngg, :st_point, geographic: true 
    add_index :oneclick_refernet_services, :latlngg, using: :gist
  end
end
