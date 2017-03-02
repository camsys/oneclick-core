class AddDefaultValueToUserEligibilities < ActiveRecord::Migration[5.0]
  def up
    change_column_default :user_eligibilities, :value, true
  end

  def down
    change_column_default :user_eligibilities, :value, nil
  end
end
