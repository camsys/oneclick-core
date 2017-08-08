class UserBookingProfile < ApplicationRecord
  belongs_to :user
  belongs_to :service
  
  serialize :details
  
end
