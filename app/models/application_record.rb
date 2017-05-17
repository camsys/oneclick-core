class ApplicationRecord < ActiveRecord::Base
  include CSVWritable # Allows records to be exported as CSV
    
  self.abstract_class = true
  
end
