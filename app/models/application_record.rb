class ApplicationRecord < ActiveRecord::Base
  include CSVSerializable # Allows records to be exported as CSV
    
  self.abstract_class = true
  
end
