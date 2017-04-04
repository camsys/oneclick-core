class CreateServicesPurposes < ActiveRecord::Migration[5.0]
  def change
    create_join_table :services, :purposes do |t|
      t.index :service_id
      t.index :purpose_id
    end
  end
end
