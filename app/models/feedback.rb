class Feedback < ApplicationRecord
  
  DEFAULT_SUBJECT = "General"
    
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
  
  
  ### METHODS ###
  
  # If no feedbackable is present, what is the feedback about?
  def default_subject
    DEFAULT_SUBJECT
  end
  
  # Returns a description of what the feedback is about
  def subject
    feedbackable.try(:to_s) || default_subject
  end
  
end
