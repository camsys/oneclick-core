# Model for storing information about API controller requests
class RequestLog < ApplicationRecord
  
  serialize :params
  
end
