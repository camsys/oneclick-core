class User < ApplicationRecord

  ### Includes ###
  rolify
  acts_as_token_authenticatable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ### Serialized Attributes ###
  serialize :preferred_trip_types #Trip types are the types of trips a user requests (e.g., transit, taxi, park_n_ride etc.)

  ### Scopes ###
  scope :staff, -> { User.with_role(:admin) }
  scope :admins, -> { User.with_role(:admin) }

  ### Associations ###
  has_many :trips
  has_and_belongs_to_many :accommodations
  belongs_to :preferred_locale, class_name: 'Locale', foreign_key: :preferred_locale_id
  has_many :user_eligibilities, dependent: :destroy
  has_many :eligibilities, through: :user_eligibilities

  # These associations allow us to pull just the confirmed or just the denied eligibilities (e.g. ones with true or false values)
  has_many :confirmed_user_eligibilities, -> { confirmed }, class_name: 'UserEligibility'
  has_many :denied_user_eligibilities, -> { denied }, class_name: 'UserEligibility'
  has_many :confirmed_eligibilities, source: :eligibility, through: :confirmed_user_eligibilities
  has_many :denied_eligibilities, source: :eligibility, through: :denied_user_eligibilities

  ### Validations ###
  validates :email, presence: true
  validates :email, uniqueness: true

  ### Instance Methods ###

  #Return a locale for a user, even if the users preferred locale is not set
  def locale
    self.preferred_locale || Locale.find_by(name: "en") || Locale.first
  end

  # Check to see if this user owns the object
  def owns? object
    case object.class.name
    when "Trip"
      return self == object.user
    when "Itinerary"
      return self == object.trip.user
    else
      return false
    end
  end

  # Check to see if the user is an Admin
  def admin?
    self.has_role? :admin
  end

  ### Update Profle from API Call ###

  def update_profile params
    update_basic_attributes params[:attributes] unless params[:attributes].nil?
    update_eligibilities params[:characteristics] unless params[:characteristics].nil?
    update_accommodations params[:accommodations] unless params[:accommodations].nil?
    return true
  end

  def update_basic_attributes params
    params.each do |key, value|
      case key.to_sym
        when :first_name
          self.first_name = value
        when :last_name
          self.last_name = value
        when :email
          self.email = value
        when :lang
          self.preferred_locale = Locale.find_by(name: value) || self.locale
        when :preferred_trip_types, :preferred_modes
          self.preferred_trip_types = value
      end
    end
    self.save
  end

  def update_eligibilities params
    params.each do |code, value|
      eligibility = Eligibility.find_by(code: code)
      if eligibility
        ue = self.user_eligibilities.where(eligibility: eligibility).first_or_create
        ue.value = value.to_bool
        ue.save
      end
    end
  end

  def update_accommodations params
    user_accommodations = self.accommodations
    params.each do |code, value|
      accommodation = Accommodation.find_by(code: code)
      if accommodation
        user_accommodations.delete(accommodation)
        if value.to_bool
          user_accommodations << accommodation
        end
      end
    end

    self.accommodations = user_accommodations

  end

  ### Hash Methods ###
  # Return Profile as a Hash
  def profile_hash
    puts "RENDERING PROFILE HASH"
    hash = {email: email, first_name: first_name, last_name: last_name}
    hash[:lang] = preferred_locale.nil? ? nil : preferred_locale.name
    hash[:characteristics] = eligibilities_hash
    hash[:accommodations] = accommodations_hash
    #TODO: Rename this to Trip Types (will break API V1)
    hash[:preferred_modes] = preferred_trip_types
    return hash
  end

  # Return Eligbilities as a Hash
  def eligibilities_hash
    eligibilities = []
    self.user_eligibilities.each do |user_eligibility|
      eligibilities << user_eligibility.api_hash
    end
    return eligibilities
  end

  # Return Accommodations as a Hash
  def accommodations_hash
    accommodations = []
    self.accommodations.each do |accommodation|
      accommodations << accommodation.api_hash(self.locale)
    end
    return accommodations
  end

end
