class AddEligibleAgesToServices < ActiveRecord::Migration[5.0]
  def change
    add_column :services, :eligible_max_age, :integer, null: false, default: 0
    add_column :services, :eligible_min_age, :integer, null: false, default: 200
  end
end
