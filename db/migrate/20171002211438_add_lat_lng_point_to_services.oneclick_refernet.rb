# This migration comes from oneclick_refernet (originally 20170818172914)
class AddLatLngPointToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :oneclick_refernet_services, :latlng, :st_point, srid: 4326
    add_index :oneclick_refernet_services, :latlng, using: :gist
  end
end
