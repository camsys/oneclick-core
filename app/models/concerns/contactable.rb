# Helper methods for formatting contact information fields

module Contactable
  
  def self.included(base)    
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    
    # Configure contact fields to format as email or telephone.
    # Assign column names to various field types: email and phone.
    # e.g. `contact_fields email: :email_col_name, phone: [:cell_phone, :home_phone]`
    def contact_fields(field_mappings={})
      setup_phone_fields(*field_mappings[:phone])
      setup_email_fields(*field_mappings[:email])
    end
    
    protected
    
    # Normalize and validate phone number column(s) with phony gem
    def setup_phone_fields(*columns)      
      columns.each do |column|
        phony_normalize column, default_country_code: 'US'
        validates column, phony_plausible: true
      end
    end
    
    # Validate email column(s)
    def setup_email_fields(*columns)
      columns.each do |column|        
        # Each column must contain a well-formed email address
        # Allows blank emails by default
        validates column, 
            allow_blank: true, 
            format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/ }
      end
    end
    
    
  end
  
end
