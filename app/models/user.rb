class User < ApplicationRecord

  ### Includes ###
  rolify  # user may be an admin, staff, traveler, ...
  include BookingHelpers::UserHelpers #has_many :booking_profiles, etc.
  include Contactable
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
  
  ### Instance Methods ###
  
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
    # Sync up with any booking services
    sync
    trips.past.limit(count)
  end

  # Returns the user's (count) future trips, in descending order of trip time
  def future_trips(count=nil)
    # Sync up with any booking services
    sync 

    trips.future.limit(count)
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

  protected

  #All Emails are Lower Case
  def downcase_email
    self.email.downcase!
  end
  
  # Set Require Confirmation to be true
  def confirmation_required?
    Config.require_user_confirmation || false
  end

end
