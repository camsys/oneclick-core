class AddAcknowledgedToFeedbacks < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :acknowledged, :boolean, index: true, default: false
  end
end
