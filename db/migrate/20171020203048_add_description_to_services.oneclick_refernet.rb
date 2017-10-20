# This migration comes from oneclick_refernet (originally 20171020192050)
class AddDescriptionToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :oneclick_refernet_services, :description, :text, index: true
  end
end
