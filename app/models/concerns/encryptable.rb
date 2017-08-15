# Helper methods for non-Devise models with encrypted columns. Leverages attr_encrypted gem.
module Encryptable
  
  def self.included(base)    
    base.extend(ClassMethods)
  end
  
  def encryption_key_from(env_variable_name)
    raise "Must set a #{env_variable_name} ENV variable!" unless ENV[env_variable_name]
    return ENV[env_variable_name]
  end
  
  def generate_encryption_key
    SecureRandom.base64(24) # This will generate a random string with 32 bytes.
  end
  
  module ClassMethods
    
    # Config method for setting up encrypted attributes using the attr_encrypted gem
    def encrypt_attribute(attr_name, env_variable_name)
      encryption_key_method_name = "encryption_key_for_#{attr_name}".to_sym
      env_variable_name = env_variable_name.to_s.underscore.upcase
      
      # Encrypt attribute using attr_encrypted gem
      attr_encrypted :external_password, key: encryption_key_method_name

      # Define the method for retrieving the encryption key from the environment
      define_method(encryption_key_method_name) do
        encryption_key_from(env_variable_name)
      end
    end
    
  end
  
end
