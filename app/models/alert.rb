class Alert < ApplicationRecord

  ### ATTRIBUTES & ASSOCIATIONS ###
  serialize :audience_details
  has_many :user_alerts, dependent: :destroy
  has_many :users, through: :user_alerts
  attr_accessor :translations

  ### CALLBACKS ###
  after_initialize :create_translation_helpers
  before_destroy :delete_translations
  before_create :set_expiration

  ### GLOBALS ###
  AUDIENCE_TYPES = [:everyone, :specific_users]
  CUSTOM_TRANSLATIONS = ["subject", "message"]

  ### SCOPES ###
  scope :expired, -> { where('expiration < ?', DateTime.now.in_time_zone).order('expiration DESC') }
  scope :current, -> { where('expiration >= ?', DateTime.now.in_time_zone).order('expiration ASC') }
  scope :is_published,  -> { where(published: true)}
  scope :for_everyone, -> { where(audience: "everyone")}

  ### Custom Update to handle creating translations.
  def update alert_params    

    # Update the normal attributes
    self.update_attributes(alert_params)

    # Pop out the translation attributes before you attempt to run update_attributes
    if alert_params["translations"]
      alert_params["translations"].each do |key, value|
        self.set_translation(key.to_s.split('_').first, key.to_s.split('_').last, value)
      end
    end

    # Deal with setting up alerts for specific users.
    warnings = self.handle_specific_users
    unless warnings.nil?
      warnings = "No users found with the following emails #{warnings}"
    end  
    return warnings

  end

  ### Translations ###
  def create_translation_helpers
  	
    # This block of code creates the following getters
  	# en_subject, es_subject, en_message, es_message, etc. 
  	I18n.available_locales.each do |locale|
  	  Alert::CUSTOM_TRANSLATIONS.each do |custom_method|
        define_singleton_method("#{locale}_#{custom_method}") do
          self.send(custom_method, locale)
        end
      end
    end

  end

  # To Label is used by SimpleForm to Get the Label
  def to_label locale=I18n.default_locale
    self.subject locale
  end

  def message locale=I18n.default_locale
    SimpleTranslationEngine.translate(locale, "alert_#{self.id}_message")
  end

  def subject locale=I18n.default_locale
    SimpleTranslationEngine.translate(locale, "alert_#{self.id}_subject")
  end

  # set translations e.g.,  locale="en", object="name", value="medical"
  def set_translation(locale, translation, value)
    SimpleTranslationEngine.set_translation(locale, "alert_#{self.id}_#{translation}", value)
  end

  def delete_translations
    Alert::CUSTOM_TRANSLATIONS.each do |custom_method|
      TranslationKey.find_by(name: "alert_#{self.id}_#{custom_method}").try(:destroy)
    end
  end
  
  def handle_specific_users 

    unless self.audience == "specific_users" and self.audience_details and self.audience_details["user_emails"]
      return nil
    end
  	
    new_user_string = [] #Collected because we will update audience details with what actually worked.
    no_user_found = [] #Collected to return a list of emails that didn't work
    self.audience_details["user_emails"].split(',').each do |email|
      user = User.find_by(email: email.strip)
      if user
      	UserAlert.where(user: user, alert: self).first_or_create
      	new_user_string << email.strip
      else
        no_user_found << email
      end
    end
    self.audience_details = {user_emails: new_user_string.join(', ')}
    self.save
    
    if no_user_found.empty?
      return nil
    else #Return a warning string
      return no_user_found.join(', ')
    end
  end

  def set_expiration
    self.expiration = self.expiration || (Time.now+7.days).at_midnight()
  end
	
end
