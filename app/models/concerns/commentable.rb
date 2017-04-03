module Commentable

  # Set up commentable association for including class
  def self.included(base)
    base.has_many :comments, as: :commentable
    base.accepts_nested_attributes_for :comments
  end

  # Find associated comment by locale
  def comment(locale)
    self.comments.find_by(locale: locale.to_s)
  end

  # Builds a comment for each available locale
  def build_comments
    I18n.available_locales.map do |l|
      comments.build(locale: l) unless comments.find_by_locale(l)
    end
  end

end
