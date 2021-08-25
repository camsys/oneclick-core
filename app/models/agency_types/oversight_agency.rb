# Oversight agency staff have broad permissions to view reports and other information.
# They may or may not have transportation services
class OversightAgency < Agency
  
  resourcify  # user roles may be scoped to agencies
  include ResourceHelper
  has_many :agency_oversight_agency, dependent: :destroy
end
