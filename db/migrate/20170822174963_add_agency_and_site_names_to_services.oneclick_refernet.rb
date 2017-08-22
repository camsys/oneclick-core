# This migration comes from oneclick_refernet (originally 20170821135337)
class AddAgencyAndSiteNamesToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :oneclick_refernet_services, :agency_name, :string, index: true
    add_column :oneclick_refernet_services, :site_name, :string, index: true
    remove_column :oneclick_refernet_services, :name, :string, index: true
  end
end
