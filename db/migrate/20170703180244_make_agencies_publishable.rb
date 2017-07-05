class MakeAgenciesPublishable < ActiveRecord::Migration[5.0]
  def change
    add_column :agencies, :published, :boolean, default: false
    add_index :agencies, :published
  end
end
