class AddDispositionStatus < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :disposition_status, :string, default: 'Unknown Disposition'
  end
end
