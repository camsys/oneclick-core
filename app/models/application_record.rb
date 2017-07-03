class ApplicationRecord < ActiveRecord::Base
  include CSVWritable # Allows records to be exported as CSV
    
  self.abstract_class = true
  
  # Converts an array of model objects into a collection query of that same set of objects
  def self.querify(array=[])
    self.where(id: array.select{|obj| obj.is_a?(self) }.pluck(:id))
  end
  
end
