class UserEligibility < ApplicationRecord

  ### Associations ###
  belongs_to :user
  belongs_to :eligibility

  ### Scopes ###
  scope :confirmed, -> { where(value: true) }
  scope :denied, -> { where(value: false) }

  ### Hash Methods ###
  def api_hash
  	{
  	  code: self.eligibility.code, 
  	  name: SimpleTranslationEngine.translate(self.user.locale.name, "eligibility_#{self.eligibility.code.to_s}_name"), 
      note: SimpleTranslationEngine.translate(self.user.locale.name, "eligibility_#{self.eligibility.code.to_s}_note"),
      question: SimpleTranslationEngine.translate(self.user.locale.name, "eligibility_#{self.eligibility.code.to_s}_question"),
  	  value: self.value 
  	}
  end


end
