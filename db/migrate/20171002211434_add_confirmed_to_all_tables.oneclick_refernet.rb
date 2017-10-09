# This migration comes from oneclick_refernet (originally 20170816142117)
class AddConfirmedToAllTables < ActiveRecord::Migration[5.0]
  def change
    
    add_column :oneclick_refernet_categories, :confirmed, :boolean, default: false, index: true
    add_column :oneclick_refernet_sub_categories, :confirmed, :boolean, default: false, index: true
    add_column :oneclick_refernet_sub_sub_categories, :confirmed, :boolean, default: false, index: true
    add_column :oneclick_refernet_services, :confirmed, :boolean, default: false, index: true
    
  end
end
