class Feedback < ApplicationRecord
  
  ### ASSOCIATIONS ###
  
  belongs_to :feedbackable, polymorphic: true
  belongs_to :user
  
  
  ### SCOPES ###
  
  scope :general, -> { where(feedbackable_id: nil)}
  
  
  ### VALIDATIONS ###
  
  validates :rating, numericality: { only_integer: true, 
                                     greater_than_or_equal_to: 0, 
                                     less_than_or_equal_to: 5,
                                     allow_nil: true }
  
end
