class Feedback < ApplicationRecord
  
  DEFAULT_SUBJECT = "General"
    
  ### INCLUDES & ASSOCIATIONS ###
  
  belongs_to :feedbackable, polymorphic: true
  belongs_to :user
  include Commentable # has_many :comments
  has_one :acknowledgement_comment, class_name: "Comment", as: :commentable
  accepts_nested_attributes_for :acknowledgement_comment
  
  ### SCOPES ###
  
  scope :general, -> { where(feedbackable_id: nil)}
  scope :newest_first, -> { order(created_at: :desc) }
  scope :pending, -> { where(acknowledged: false).newest_first }
  scope :acknowledged, -> { where(acknowledged: true).newest_first }
  
  
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
  
  # Alias for acknowledged boolean attribute
  def acknowledged?
    acknowledged
  end
  
  
  
  
end
