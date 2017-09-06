# Partner agency staff have broad permissions to view reports and other information.
# They may or may not have transportation services
class PartnerAgency < Agency
  
  resourcify  # user roles may be scoped to agencies
  include ResourceHelper
  
end
