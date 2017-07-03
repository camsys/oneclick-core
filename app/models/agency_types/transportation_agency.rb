# Transportation Agencies have transportation services, and their staff may
# only view reports relevant to the agency
class TransportationAgency < Agency

  resourcify  # user roles may be scoped to transportation agencies
    
end
