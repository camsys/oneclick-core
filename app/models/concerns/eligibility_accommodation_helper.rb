module EligibilityAccommodationHelper

  def snake_casify
  	 self.code = self.code.parameterize.underscore
  end

end
