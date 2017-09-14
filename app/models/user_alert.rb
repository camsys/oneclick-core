class UserAlert < ApplicationRecord
	belongs_to :user
	belongs_to :alert

	scope :is_acknowledged,  -> { where(acknowledged: true)}
 	scope :is_not_acknowledged,  -> { where(acknowledged: false)}
 	scope :is_published, -> { joins(:alert).where('alerts.published = ?', true) }
 	scope :is_current, -> { joins(:alert).where('alerts.expiration >= ?', DateTime.now.in_time_zone).order('expiration ASC') }

	def subject
		alert.subject user.preferred_locale.name || :en
	end

	def message
		alert.message user.preferred_locale.name || :en
	end
end
