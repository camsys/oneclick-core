class Alert < ApplicationRecord

  ### SCOPES ###
  scope :expired, -> { where('expiration < ?', DateTime.now.in_time_zone).order('expiration DESC') }
  scope :current, -> { where('expiration >= ?', DateTime.now.in_time_zone).order('expiration DESC') }
	
end
