Rolify.configure do |config|
  # By default ORM adapter is ActiveRecord. uncomment to use mongoid
  # config.use_mongoid

  # Dynamic shortcuts for User class (user.is_admin? like methods). Default is: false
  # config.use_dynamic_shortcuts
  
  # Instantiating the resource classes causes them to be added to Rolify.resource_types
  resource_classes = [TransportationAgency, PartnerAgency]
  
  
end
