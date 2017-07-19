module Commentable

  # Set up commentable association for including class
  def self.included(base)
    base.has_many :comments,
      -> { order(:locale) }, # alphabetize by locale
      as: :commentable, # polymorphic
      dependent: :destroy # destroy comments on model destruction
    base.accepts_nested_attributes_for :comments
    
    base.extend(ValidationConfigMethods)
  end

  # Find associated comment by locale
  def comment(locale)
    self.comments.find_by(locale: locale.to_s)
  end
  
  # Builds a comment for the specified locale if it doesn't exist already
  def build_comment(locale, attrs={})
    comment = comments.find_by_locale(locale) || comments.build(locale: locale)
    comment.assign_attributes(attrs)
    comment
  end

  # Builds a comment for each available locale if it doesn't exist already
  def build_comments
    I18n.available_locales.map { |l| build_comment(l) }
  end
  
  # Builds comments from a hash, with locales as keys
  def build_comments_from_hash(comments_hash)
    comments_hash.map do |locale, comment|
      build_comment(locale, comment: comment)
    end
  end
  
  # Class Methods for configuring comment validations
  module ValidationConfigMethods
    def validates_comment_uniqueness_by_locale
      define_method("validates_comment_uniqueness_by_locale?") do
        true
      end
    end
    
    def validates_comment_commenter_presence
      define_method("validates_comment_commenter_presence?") do
        true
      end
    end
  end
  
  ### Default validation config methods ###
  def validates_comment_uniqueness_by_locale?() false end
  def validates_comment_commenter_presence?() false end
  

end
