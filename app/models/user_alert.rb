class UserAlert < ApplicationRecord
	belongs_to :user
	belongs_to :alert

	scope :is_acknowledged,  -> { where(acknowledged: true)}
 	scope :is_not_acknowledged,  -> { where(acknowledged: false)}
 	scope :is_published, -> { joins(:alert).where('alerts.published = ?', true) }
 	scope :is_current, -> { joins(:alert).where('alerts.expiration >= ?', DateTime.now.in_time_zone).order('expiration ASC') }

	def subject
		alert.subject (user.preferred_locale.try(:name) || I18n.default_locale)
	end

	def message
		alert.message (user.preferred_locale.try(:name) || I18n.default_locale)
	end
end
