class Eligibility < ApplicationRecord

  before_save :snake_casify

  def snake_casify
    self.code = self.code.parameterize.underscore 	
  end

end
