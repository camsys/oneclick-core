class AddSubscribedToEmailsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :subscribed_to_emails, :boolean, default: true
  end
end
