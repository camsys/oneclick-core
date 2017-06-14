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

  # Builds a comment for each available locale
  def build_comments
    I18n.available_locales.map do |l|
      comments.build(locale: l) unless comments.find_by_locale(l)
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
