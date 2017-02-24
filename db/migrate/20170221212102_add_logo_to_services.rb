class AddLogoToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :logo, :string
  end
end
