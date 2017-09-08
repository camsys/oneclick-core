class User < ApplicationRecord

  ### Includes ###
  rolify  # user may be an admin, staff, traveler, ...
  include BookingHelpers::UserHelpers #has_many :booking_profiles, etc.
  include Contactable
  include RoleHelper
  acts_as_token_authenticatable
  include TokenAuthenticationHelpers
  include TravelerProfileUpdater   # Update Profile from API Call
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  write_to_csv with: Admin::UsersReportCSVWriter


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


  ### Associations ###
  has_many :trips, dependent: :nullify
  has_many :itineraries, through: :trips
  has_and_belongs_to_many :accommodations
  belongs_to :preferred_locale, class_name: 'Locale', foreign_key: :preferred_locale_id
  has_many :user_eligibilities, dependent: :destroy
  has_many :eligibilities, through: :user_eligibilities
  has_many :feedbacks
  has_many :stomping_grounds
  has_many :user_alerts
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
  
  ### Class Methods ###


  
  ### Instance Methods ###
  
  # To String prints out user's email address
  def to_s
    email
  end
  
  # Returns the user's full name
  def full_name
    "#{first_name} #{last_name}"
  end
  
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

  # Returns the user's (count) past trips, in descending order of trip time
  def past_trips(count=nil)
    trips.past.limit(count)
  end

  # Returns the user's (count) future trips, in descending order of trip time
  def future_trips(count=nil)
    trips.future.limit(count)
  end

  # Returns the (count) most recent places from trips planned by the user.
  def recent_waypoints(count=nil)
    trips.waypoints.order(created_at: :desc).limit(count)
  end


end
