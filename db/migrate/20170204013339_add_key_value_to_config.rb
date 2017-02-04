class AddKeyValueToConfig < ActiveRecord::Migration[5.0]
  def change
  	add_column :configs, :key, :string
  	add_column :configs, :value, :text
  end
end
