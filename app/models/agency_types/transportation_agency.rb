# Transportation Agencies have transportation services, and their staff may
# only view reports relevant to the agency
class TransportationAgency < Agency

  resourcify  # user roles may be scoped to transportation agencies
  include ResourceHelper
  has_one :agency_oversight_agency, dependent: :destroy
  has_many :traveler_transit_agencies, dependent: :destroy
end
