# Transportation Agencies have transportation services, and their staff may
# only view reports relevant to the agency
class TransportationAgency < Agency

  resourcify  # user roles may be scoped to transportation agencies
  
  has_many :services

  # All the users that have a staff role scoped to this agency
  def staff
    User.with_role(:staff, self)
  end
  
  # accepts_nested_attributes_for :services

end
