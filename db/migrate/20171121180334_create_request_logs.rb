class CreateRequestLogs < ActiveRecord::Migration[5.0]
  def change
    create_table :request_logs do |t|
      t.string :controller
      t.string :action
      t.string :status_code
      t.text :params
      t.string :auth_email
      t.integer :duration

      t.timestamps
    end
    
    # Index on controller then on action, rather than just on action
    add_index :request_logs, [:controller, :action]
  end
end
