# This migration comes from oneclick_refernet (originally 20201015173006)
class AddLocationDetailsToService < ActiveRecord::Migration[5.0]
  def change
    add_column :oneclick_refernet_services, :location_details, :text
  end
end
