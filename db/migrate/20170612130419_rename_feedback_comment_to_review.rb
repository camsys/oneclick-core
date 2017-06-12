class RenameFeedbackCommentToReview < ActiveRecord::Migration[5.0]
  def change
    rename_column :feedbacks, :comment, :review
  end
end
