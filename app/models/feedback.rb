class Feedback < ApplicationRecord
  
  belongs_to :feedbackable, polymorphic: true
  belongs_to :user
  
  scope :general, -> { where(feedbackable_id: nil)}
  
end
