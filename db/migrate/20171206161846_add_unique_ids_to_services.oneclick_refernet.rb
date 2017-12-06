# This migration comes from oneclick_refernet (originally 20171206151757)
class AddUniqueIdsToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :oneclick_refernet_services, :refernet_service_id, :integer, index: true
    add_column :oneclick_refernet_services, :refernet_location_id, :integer, index: true
    add_column :oneclick_refernet_services, :refernet_servicesite_id, :integer, index: true
  end
end
