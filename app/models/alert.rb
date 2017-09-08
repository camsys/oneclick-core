class Alert < ApplicationRecord

  ### ATTRIBUTES & ASSOCIATIONS ###
  serialize :audience_details
  has_many :user_alerts
  has_many :users, through: :user_alerts


  ### CALLBACKS ###
  after_initialize :create_translation_helpers

  ### GLOBALS ###
  AUDIENCE_TYPES = [:everyone, :specific_users]

  ### SCOPES ###
  scope :expired, -> { where('expiration < ?', DateTime.now.in_time_zone).order('expiration DESC') }
  scope :current, -> { where('expiration >= ?', DateTime.now.in_time_zone).order('expiration ASC') }
  scope :is_published,  -> { where(published: true)}


  ### Translations ###
  def create_translation_helpers
  	# This block of code creates the following helpers
  	# en_subject, es_subject, en_message, es_message, etc. 
  	I18n.available_locales.each do |locale|
  	  ["subject", "message"].each do |custom_method|
        define_singleton_method("#{locale}_#{custom_method}") do
          self.send(custom_method, locale)
        end
      end
    end
  end

  # To Label is used by SimpleForm to Get the Label
  def to_label locale=:en
    self.subject locale
  end

  def message locale=:en
    SimpleTranslationEngine.translate(locale, "alert_#{self.id}_message")
  end

  def subject locale=:en
    SimpleTranslationEngine.translate(locale, "alert_#{self.id}_subject")
  end

  # set translations e.g.,  locale="en", object="name", value="medical"
  def set_translation(locale, translation, value)
    SimpleTranslationEngine.set_translation(locale, "alert_#{self.id}_#{translation}", value)
  end
  
  def handle_specific_users audience_details
  	new_user_string = []
    audience_details["user_emails"].strip.split(',').each do |email|
      user = User.find_by(email: email)
      if user
      	UserAlert.where(user: user, alert: self).first_or_create
      	new_user_string << email
      end
    end
    self.audience_details = {user_emails: new_user_string.join(', ')}
    self.save
    return self.audience_details
  end
	
end
