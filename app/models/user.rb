class User < ApplicationRecord

  ### Includes ###
  rolify  # user may be an admin, staff, traveler, ...
  include BookingHelpers::UserHelpers #has_many :booking_profiles, etc.
  include Contactable
  include RolifyAddons
  include RoleHelper
  include TokenAuthenticationHelpers
  include TravelerProfileUpdater   # Update Profile from API Call
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :lockable, :confirmable
  write_to_csv with: Admin::UsersReportCSVWriter

  # acts_as_token_authenticatable unless it's a guest user
  before_save :ensure_authentication_token, unless: :guest_user?


  ### Serialized Attributes ###
  serialize :preferred_trip_types #Trip types are the types of trips a user requests (e.g., transit, taxi, park_n_ride etc.)

  ### Scopes ###
  scope :with_accommodations, -> (accommodation_ids) do
    joins(:accommodations).where(accommodations: { id: accommodation_ids })
  end

  scope :with_eligibilities, -> (eligibility_ids) do
    joins(:confirmed_eligibilities).where(eligibilities: { id: eligibility_ids })
  end
  
  # Active between scopes check if user has planned trips before or after given dates
  scope :active_since, -> (date) do
    joins(:trips).merge(Trip.from_date(date))
  end

  scope :active_until, -> (date) do
    joins(:trips).merge(Trip.to_date(date))
  end
  
  # Users with the subscribed_to_emails flag set to true
  scope :subscribed_to_emails, -> { where(subscribed_to_emails: true) }


  ### Associations ###
  has_one :traveler_transit_agency, dependent: :destroy
  has_one :transportation_agency, through: :traveler_transit_agency
  belongs_to :current_agency, class_name:'Agency', foreign_key: :current_agency_id
  has_many :trips, dependent: :nullify
  has_many :itineraries, through: :trips
  has_many :origins, through: :trips
  has_many :destinations, through: :trips
  has_and_belongs_to_many :accommodations, -> { distinct }
  belongs_to :preferred_locale, class_name: 'Locale', foreign_key: :preferred_locale_id
  has_many :user_eligibilities, dependent: :destroy
  has_many :eligibilities, -> { distinct }, through: :user_eligibilities
  has_many :feedbacks
  has_many :stomping_grounds
  has_many :user_alerts, dependent: :destroy
  has_many :alerts, through: :user_alerts
  has_many :user_booking_profiles

  # These associations allow us to pull just the confirmed or just the denied eligibilities (e.g. ones with true or false values)
  has_many :confirmed_user_eligibilities, -> { confirmed }, class_name: 'UserEligibility'
  has_many :denied_user_eligibilities, -> { denied }, class_name: 'UserEligibility'
  has_many :confirmed_eligibilities, source: :eligibility, through: :confirmed_user_eligibilities
  has_many :denied_eligibilities, source: :eligibility, through: :denied_user_eligibilities

  ### Validations ###
  contact_fields email: :email
  validates :email, presence: true, uniqueness: true
  validates :password_confirmation, presence: true, on: :create
  before_save :downcase_email
  validate :password_complexity

  ### Attribute Accessors ###
  attr_accessor :county

  ### Instance Methods ###
  # Custom initializer with instance variable instantiation
  def initialize(attributes={})
    super
    @county ||= return_county_if_ecolane_email
  end


  # To String prints out user's email address
  def to_s
    email
  end
  
  # Returns the user's full name
  def full_name
    [first_name, last_name].select(&:present?).join(' ')
  end
  
  # Returns the user's full name, or email if that's blank
  def full_name_or_email
    full_name.strip.present? ? full_name : email
  end
  
  #Return a locale for a user, even if the users preferred locale is not set
  def locale
    self.preferred_locale || Locale.find_by(name: I18n.default_locale) || Locale.first
  end
  
  # Returns true/false if a user is a guest user, based on email form
  def guest_user?
    GuestUserHelper.new.is_guest_email?(email)
  end
  
  # Alias for subscribed_to_emails boolean
  def subscribed_to_emails?
    self.subscribed_to_emails
  end

  def county_name_if_ecolane_email
    regex = /ecolane_user\.com$/

    if regex.match(email)
      email.split('@').first&.split('_').last&.downcase&.capitalize
    else
      nil
    end
  end

  def return_county_if_ecolane_email
    county = county_name_if_ecolane_email

    if county
      County.find_by(name: county)
    end
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

  # Returns the user's (count) past trips, in descending order of trip time
  def past_trips(count=nil)
    trips.selected.past.past_14_days.limit(count)
  end

  # Returns the user's (count) future trips, in descending order of trip time
  def future_trips(count=nil)
    # Sync up with any booking services
    sync 
    trips.selected.future.limit(count)
  end

  # Returns an unordered collection of the traveler's waypoints
  def waypoints
    trips.waypoints
  end

  # Returns the (count) most recent places from trips planned by the user.
  def recent_waypoints(count=nil)
    trips.waypoints.order(created_at: :desc).limit(count)
  end

  # Instead of creating potentially thousands of user_alerts each time an alert is created,
  # create them whenever this call is run.  Run this call before you return alerts for a user.
  def update_alerts
    alerts_for_everybody = Alert.current.is_published.for_everyone
    my_alerts = self.alerts.current.is_published
    alerts_to_add = alerts_for_everybody - my_alerts

    alerts_to_add.each do |alert|
      UserAlert.create!(user: self, alert: alert)
    end
  end
  
  # Add accommodations to the user by code(s)
  def add_accommodations(*codes)
    accs = codes.map {|code| Accommodation.find_by(code: code) }
                .compact.uniq
                .select { |acc| !self.accommodations.include?(acc) }
    self.accommodations << accs
  end
  
  # Adds eligibilities to the user by code(s)
  def add_eligibilities(*codes)
    eligs = codes.map {|code| Eligibility.find_by(code: code) }
                .compact.uniq
                .select { |elig| !self.eligibilities.include?(elig) }
    self.eligibilities << eligs
  end

  ##
  # TODO(Drew) write documentation comment
  def get_services
    county = county_name_if_ecolane_email
    if county.nil?
      # County name may be null if user has set email to a non-Ecolane email address.
      # Search for county that user logged in as from most recent user booking profile.
      # User booking profile is updated with county at login.
      most_recent_booking_profile_details = booking_profiles.order("updated_at DESC").first&.details
      if most_recent_booking_profile_details && most_recent_booking_profile_details[:county]
        county = most_recent_booking_profile_details[:county]
      end
    end
    # Since a user can only have one TravelerTransitAgency why not just put the transportation_agency_id on the user table?
    Service.joins("LEFT JOIN traveler_transit_agencies ON services.agency_id = traveler_transit_agencies.transportation_agency_id")
            .merge( TravelerTransitAgency.where(user_id: id) )
            .with_home_county(county)
            .paratransit_services
            .published
            .is_ecolane
  end

  ##
  # TODO(Drew) write documentation comment
  # TODO(Drew) change to (Home?) (Para?) (Ecolane?) Transit Service
  def current_service
    get_services.first
  end

  ##
  # TODO(Drew) write documentation comment
  def get_funding_data(service=nil)
    funding_hash = {}
    profile = service ? booking_profile_for(service) : booking_profile
    return funding_hash unless profile

    get_funding = true
    customer = profile.booking_ambassador
                      .fetch_customer_information(get_funding)
                      .fetch('customer', {})
    funding_options = [
      customer.fetch('funding', {})
              .fetch('funding_source', {})
    ].flatten
    
    funding_options.each do |funding_source|
      allowed_purposes = [funding_source['allowed']].flatten
      allowed_purposes.each do |allowed_purpose|
        purpose = allowed_purpose['purpose'].strip
        funding_hash[purpose] ||= []
        funding_hash[purpose].push(funding_source['name'].strip)
      end
    end

    funding_hash
  end

  protected

  #All Emails are Lower Case
  def downcase_email
    self.email.downcase!
  end
  
  # Set Require Confirmation to be true
  def confirmation_required?
    Config.require_user_confirmation || false
  end

  def password_complexity
    if password.present? and not password.match(/^(?=.*[0-9])(?=.*[A-Za-z])([-a-zA-Z0-9`~\!@#$%\^&*()-_=\+\[\{\]\}\\|;:'",<.>? ]+)$/)
      errors.add :password, "must include at least one letter and one digit"
    end
  end

end
