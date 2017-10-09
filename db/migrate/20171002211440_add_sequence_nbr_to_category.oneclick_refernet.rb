# This migration comes from oneclick_refernet (originally 20171002203907)
class AddSequenceNbrToCategory < ActiveRecord::Migration[5.0]
  def change
  	add_column :oneclick_refernet_categories, :sequence_nbr, :integer, index: true
  end
end
