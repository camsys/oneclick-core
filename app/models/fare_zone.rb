class FareZone < ApplicationRecord

  ### ASSOCIATIONS ###
  belongs_to :service
  belongs_to :region

  ### INSTANCE METHODS ###

  # Custom attr_reader returns a symbol
  def code
    super.to_sym if super.respond_to?(:to_sym)
  end

end
