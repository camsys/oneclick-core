# Helper for storing info about and creating guest users
class GuestUserHelper
  
  def initialize
  end
  
  # Return a new guest user, but don't persist to database
  def build_guest(params={})
    User.new(default_params.merge(params))
  end
  
  # Return a new guest user and save it to the database
  def create_guest(params={})
    User.create(default_params.merge(params))
  end
  
  # Default guest user params
  def default_params
    {
      first_name: "Guest",
      last_name: "User",
      email: random_email
    }
  end
  
  # Random guest user email address
  def random_email
    "guest_#{Time.now.to_i}#{rand(100)}@#{email_domain}"
  end
  
  # Email domain name to user for guest users
  def email_domain
    Config.guest_user_email_domain || "example.com"
  end
  
  # Check if a string includes the guest user email domain
  def is_guest_email?(email)
    email.include?(email_domain)
  end
  
  # Returns a SQL query string for finding guest users
  def query_str
    "email LIKE '%@#{email_domain}%'"
  end
  
end
