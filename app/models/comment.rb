class Comment < ApplicationRecord

  # May belong to any commentable model
  belongs_to :commentable, polymorphic: true

  # There should only be one comment per locale for each commentable item
  validates :locale, uniqueness: { scope: [:commentable_type, :commentable_id] }

end
