# This migration comes from oneclick_refernet (originally 20170817143457)
class AddDetailsToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :oneclick_refernet_services, :details, :text
  end
end
