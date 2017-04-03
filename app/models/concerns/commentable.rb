module Commentable

  # Set up commentable association for including class
  def self.included(base)
    base.has_many :comments, as: :commentable
  end

  # Find associated comment by locale
  def comment(locale)
    self.comments.find_by(locale: locale.to_s)
  end
end
