class MakeServicesPublishable < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :published, :boolean, default: false
    add_index :services, :published
  end
end
