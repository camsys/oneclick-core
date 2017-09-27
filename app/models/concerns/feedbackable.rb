# Include this module on Feedbackable models

# NOTE: Include any incluing models in the array in config/initializers/feedbackables.rb
  # this will prevent strange validation behavior, esp. in testing environment.
  
module Feedbackable
  @@feedbackables = []

  # Returns the average rating for the feedbackable
  def rating
    return nil if ratings.empty?
    ratings.reduce(&:+) / ratings.length.to_f
  end
  
  # Returns the number of ratings for this feedbackable
  def ratings_count
    ratings.count
  end
  
  # All of the scores in feedbacks associated with this feedbackable
  def ratings
    self.feedbacks.pluck(:rating).compact.map {|r| r.to_f }
  end
  
  # Include class methods
  def self.included(base)    
    @@feedbackables << base.name
    base.has_many :feedbacks, as: :feedbackable
    base.extend(ClassMethods)
  end

  module ClassMethods
  end
  
  
  ### MODULE METHODS ###
  
  # Returns the list of feedbackable classes
  def self.feedbackables
    @@feedbackables
  end
  
end
