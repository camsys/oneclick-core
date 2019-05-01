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
      setup_url_fields(*field_mappings[:url])
    end
    
    protected
    
    
    # Normalize and validate phone number column(s) with phony gem
    def setup_phone_fields(*columns)      
      columns.each do |column|
        phony_normalize column, if: -> { PhonyRails.plausible_number?(self.send(column)) }
        
        define_method("formatted_#{column}") do
          
          # If number is phony plausible, i.e. if the Phony gem knows how to format it, send back the formatted version
          if Phony.plausible?(self.send(column))
            self.send(column).to_s.phony_formatted
          else # Otherwise, send back the raw string
            self.send(column)
          end
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
            format: { with: /\A([^@\s]+)@((?:[-_a-zA-Z0-9]+\.)+[a-zA-Z]{2,})(\${2}.*)?\Z/ }
            # NOTE: The last part of the regex, "(\${2}.*)?", captures an appended id # after '$$', for importing from Legacy 1Click
            # NOTE: The '_' in '[-_a-z0-9]' allows for import of ecolane users, though underscores in domain names are not strictly allowed
      end
    end
    
    # Validates and normalizes URL fields by making sure they're prefixed with "http" or "https"
    def setup_url_fields(*columns)      
      columns.each do |column|
        
        # Define a method to format the URL string before validation
        # method will automatically prefix the string with http:// if
        # a scheme is not present
        define_method("format_#{column}") do
          scheme = (self.send(column).to_s.match(/([a-zA-Z][\-+.a-zA-Z\d]*):.*$/).try(:captures) || [])[0]
          if(self.send(column).present?)
            formatted_url = scheme.present? ? self.send(column) : ("http://" + self.send(column))
            self.send("#{column}=", formatted_url)
          end
        end
        
        # Call the url formatting method before validation
        before_validation "format_#{column}".to_sym
        
        # Validates the url column based on Ruby's built-in URI format regex
        validates column,
          allow_blank: true,
          format: { with: URI.regexp }
      end
    end
    
  end
  
end
