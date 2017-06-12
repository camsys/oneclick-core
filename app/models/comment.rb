class Comment < ApplicationRecord

  ### ASSOCIATIONS ###

  # May belong to any commentable model
  belongs_to :commentable, polymorphic: true
  
  # May have a commenter (the user who created the comment)
  belongs_to :commenter, class_name: "User"
  alias_method :user, :commenter # Can user comment.user or comment.commenter

  ### VALIDATIONS ###

  # There should only be one comment per locale for each commentable item (OPTIONAL)
  validates :locale, uniqueness: { scope: [:commentable_type, :commentable_id] }, if: :commentable_validates_uniqueness_by_locale
  
  # User commenter must be present
  validates :commenter, presence: true, if: :commentable_validates_commenter_presence
  
  ### METHODS ###
  
  private
  
  # Tests if the commentable model validates uniquess by locales
  def commentable_validates_uniqueness_by_locale
    commentable.validates_comment_uniqueness_by_locale?
  end
  
  # Tests if the commentable model validates commenter presence
  def commentable_validates_commenter_presence
    commentable.validates_comment_commenter_presence?
  end

end
