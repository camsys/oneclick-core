# Include this module on Feedbackable models
module Feedbackable

  # Returns the average rating for the record
  def rating
    ratings = self.feedbacks.pluck(:rating).compact.map {|r| r.to_f }
    ratings.reduce(&:+) / ratings.length
  end
  
  # # Include class methods
  # def self.included(base)
  #   base.extend(ClassMethods)
  # end
  # 
  # module ClassMethods
  #   
  # end
  
end
