class ApplicationRecord < ActiveRecord::Base
  include CSVWritable # Allows records to be exported as CSV
    
  self.abstract_class = true
  
  # Converts an array of model objects into a collection query of that same set of objects
  def self.querify(array=[])
    self.where(id: array.select{|obj| obj.is_a?(self) }.pluck(:id))
  end
  
  # Returns a collection of n random records
  def self.random(n=1)
    self.order("RANDOM()").limit(n)
  end
  
  # Returns 1 random record
  def self.find_random
    self.random(1).first
  end
  
end
