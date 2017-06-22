class StompingGround < Place

  # A user has many stomping grounds.  Stomping grounds are a user's personal places, e.g., doctor's office, home, work, etc.
  
  # Associations
  belongs_to :user

end
