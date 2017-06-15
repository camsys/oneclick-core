class AddEmailAndPhoneNumberToFeedback < ActiveRecord::Migration[5.0]
  def change
    add_column :feedbacks, :email, :string
    add_column :feedbacks, :phone, :string
  end
end
