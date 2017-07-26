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
        phony_normalize column, if: -> { PhonyRails.plausible_number?(self.send(column)) }
        
        define_method("formatted_#{column}") do
          self.send(column).to_s.phony_formatted
        end
        
      end
    end
    
    # Validate email column(s)
    def setup_email_fields(*columns)
      columns.each do |column|        
        # Each column must contain a well-formed email address
        # Allows blank emails by default
        validates column, 
            allow_blank: true, 
            format: { with: /\A([^@\s]+)@((?:[-_a-z0-9]+\.)+[a-z]{2,})(\${2}.*)?\Z/ }
            # NOTE: The last part of the regex, "(\${2}.*)?", captures an appended id # after '$$', for importing from Legacy 1Click
            # NOTE: The '_' in '[-_a-z0-9]' allows for import of ecolane users, though underscores in domain names are not strictly allowed
      end
    end
        
    
  end
  
end
