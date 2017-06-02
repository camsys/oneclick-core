class CreateFeedbacks < ActiveRecord::Migration[5.0]
  def change
    create_table :feedbacks do |t|
      t.references :feedbackable, polymorphic: true, index: true
      t.references :user, index: true
      t.integer :rating
      t.text :comment
      
      t.timestamps
    end
  end
end
