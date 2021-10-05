class AgencyOversightAgency < ApplicationRecord
  belongs_to :oversight_agency
  belongs_to :transportation_agency
end
