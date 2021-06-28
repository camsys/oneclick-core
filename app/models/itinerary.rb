class Itinerary < ApplicationRecord
  
  ### INCLUDES ###
  include BookingHelpers::ItineraryHelpers
  
  ### ATTRIBUTES & ASSOCIATIONS ###
  belongs_to :trip
  belongs_to :service
  has_one :user, through: :trip
  has_one :selecting_trip, foreign_key: "selected_itinerary_id", class_name: "Trip"
  has_one :uber_extension, dependent: :destroy
  has_one :lyft_extension, dependent: :destroy

  serialize :legs

  ### SCOPES & CONFIG ###
  scope :transit_itineraries, -> { joins(:service).where('services.type = ?', 'Transit') }
  scope :paratransit_itineraries, -> { joins(:service).where('services.type = ?', 'Paratransit') }
  scope :taxi_itineraries, -> { joins(:service).where('services.type = ?', 'Taxi') }

  before_save :calculate_start_and_end_time

  
  ### INSTANCE METHODS ###
  
  # Returns the legs array, with each leg translated into the given locale
  def translated_legs(locale=I18n.default_locale)
    OTPTranslator.new(locale).translate_legs(legs)
  end

  # Duration virtual attribute sums all trip_time attributes
  def duration # (in seconds)
    if self.end_time and self.start_time 
      return (self.end_time - self.start_time).to_i
    end
    walk_time.to_i +
    transit_time.to_i +
    wait_time.to_i
  end

  # Makes this itinerary the selected itinerary for the trip
  def select
    self.trip.update(selected_itinerary: self)
  end
  
  # Is this the trip's selected itinerary?
  def selected?
    trip.selected_itinerary == self
  end

  def unselect
    if self.selecting_trip
      self.selecting_trip.unselect
    else
      false
    end
  end

  # Calculates start and end time based on arrive_by, trip_time, and duration
  def calculate_start_and_end_time
    return false if trip.nil?

    if self.start_time.nil?
      self.start_time = trip.arrive_by ? trip.trip_time - duration : trip.trip_time
    end

    if self.end_time.nil?
      self.end_time = trip.arrive_by ? trip.trip_time : trip.trip_time + duration
    end
  end

  def describe_cost
    if cost > 0
      sprintf "$%.2f", cost
    else
      "Free"
    end
  end 

  # duplicate front end descriptions
  def end_time_desc(booking)
    return "" if booking.nil?
    seconds = (duration && duration.abs()) || 0
    result = (booking.estimated_do) || (booking.negotiated_do) || (start_time && (start_time + seconds.seconds))
    if result.nil?
      return "TBD"
    end
    result.strftime("%l:%M %p")
  end

end
