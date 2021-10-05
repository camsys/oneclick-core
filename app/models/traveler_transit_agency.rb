class TravelerTransitAgency < ApplicationRecord
  belongs_to :transportation_agency
  belongs_to :user
end
