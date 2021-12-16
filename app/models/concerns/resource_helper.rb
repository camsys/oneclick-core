# helper module for rolify resourcified classes
module ResourceHelper
  
  ### SCOPES & CLASS METHODS ###
  
  def self.included(base)
    
    base.extend(ClassMethods)
    
    base.after_save :create_staff_role
    base.after_save :create_admin_role

  end
  
  # CLASS METHOD DEFINITIONS
  module ClassMethods
  end
  
  
  ### INSTANCE METHODS ###
  
  # Create a staff role for the agency
  def create_staff_role    
    Role.where(name: "staff", resource_id: self.id, resource_type: self.class.name).first_or_create
  end

  # Create a staff role for the agency
  def create_admin_role
    Role.where(name: "admin", resource_id: self.id, resource_type: self.class.name).first_or_create
  end
  
  
end
