# This migration comes from oneclick_refernet (originally 20170816135727)
class CreateOneclickRefernetServices < ActiveRecord::Migration[5.0]
  def change
    create_table :oneclick_refernet_services do |t|
      t.string :name, index: true

      t.timestamps
    end
  end
end
