class Feedback < ApplicationRecord
    
  ### INCLUDES & ASSOCIATIONS ###
  
  belongs_to :feedbackable, polymorphic: true
  belongs_to :user
  include Commentable # has_many :comments
  
  
  ### SCOPES ###
  
  scope :general, -> { where(feedbackable_id: nil)}
  
  
  ### VALIDATIONS ###
  
  validates :rating, numericality: { only_integer: true, 
                                     greater_than_or_equal_to: 0, 
                                     less_than_or_equal_to: 5,
                                     allow_nil: true }
  validates_comment_commenter_presence
  
end
