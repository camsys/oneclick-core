# Include this module on Feedbackable models

# NOTE: Include any incluing models in the array in config/initializers/feedbackables.rb
  # this will prevent strange validation behavior, esp. in testing environment.
  
module Feedbackable
  @@feedbackables = []

  # Returns the average rating for the record
  def rating
    ratings = self.feedbacks.pluck(:rating).compact.map {|r| r.to_f }
    ratings.reduce(&:+) / ratings.length
  end
  
  # Include class methods
  def self.included(base)
    @@feedbackables << base.name
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
