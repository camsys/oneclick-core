class TravelPattern < ApplicationRecord
  scope :ordered, -> {joins(:agency).order("agencies.name, travel_patterns.name")}
  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> (user) {where(agency: user.current_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.current_agency.id]))}
  scope :for_current_transport_user, -> (user) {where(agency: user.current_agency)}
  scope :for_transport_user, -> (user) {where(agency: user.staff_agency)}
  scope :for_date, -> (date) do
    joins(:service_schedules, :booking_window)
      .merge(ServiceSchedule.for_date(date))
      .merge(BookingWindow.for_date(date))
  end

  belongs_to :agency
  belongs_to :booking_window
  belongs_to :origin_zone, class_name: 'OdZone'
  belongs_to :destination_zone, class_name: 'OdZone'

  has_many :travel_pattern_services, dependent: :destroy
  has_many :services, through: :travel_pattern_services, dependent: :restrict_with_error
  has_many :travel_pattern_service_schedules, dependent: :destroy
  has_many :service_schedules, through: :travel_pattern_service_schedules
  has_many :travel_pattern_purposes, dependent: :destroy
  has_many :purposes, through: :travel_pattern_purposes
  has_many :travel_pattern_funding_sources, dependent: :destroy
  has_many :funding_sources, through: :travel_pattern_funding_sources

  accepts_nested_attributes_for :travel_pattern_service_schedules, allow_destroy: true, reject_if: proc { |attr| attr[:service_schedule_id].blank? }
  accepts_nested_attributes_for :travel_pattern_purposes, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :travel_pattern_funding_sources, allow_destroy: true, reject_if: :all_blank

  validates :name, uniqueness: {scope: :agency_id}
  # TODO: verify whether the presence of a service schedule is good enough, or if it has to be a specific kind of schedule.
  validates_presence_of :name, :booking_window, :agency, :origin_zone, :destination_zone, :funding_sources, :purposes, :service_schedules

  def to_api_response
    travel_pattern_opts = { 
      only: [:id, :agency_id, :name, :description],
      methods: :to_calendar
    }

    self.as_json(travel_pattern_opts)
  end

  def self.for_user(user)
    if user.superuser?
      for_superuser.ordered
    elsif user.currently_oversight?
      for_oversight_user(user).ordered
    elsif user.currently_transportation?
      for_current_transport_user(user).order("name desc")
    elsif user.transportation_user?
      for_transport_user(user).order("name desc")
    else
      nil
    end
  end

  def schedules_by_type
    pre_loaded = self.association(:travel_pattern_service_schedules).loaded?

    # Prepping the return value
    schedules_by_type = {
      weekly_schedules: [],
      extra_service_schedules: [],
      reduced_service_schedules: [],
    }

    # Get all associated schedules (in reverse alphabetical order)
    service_schedules = pre_loaded ? 
                          self.travel_pattern_service_schedules.to_a :
                          self.travel_pattern_service_schedules
                            .eager_load(service_schedule: [:service_schedule_type, :service_sub_schedules])
                            .joins(:service_schedule)
                            .merge(ServiceSchedule.order(name: :desc))
                            .to_a
    
    # Sort Schedules by type
    # This also reverses the order, so now they're sorted alphabetically
    while service_schedules.length > 0 do
      schedule = service_schedules.pop

      schedules_by_type[:weekly_schedules].push(schedule) if schedule.is_a_weekly_schedule?
      schedules_by_type[:extra_service_schedules].push(schedule) if schedule.is_an_extra_service_schedule?
      schedules_by_type[:reduced_service_schedules].push(schedule) if schedule.is_a_reduced_service_schedule?
    end

    return schedules_by_type
  end

  def to_calendar
    travel_pattern_service_schedules = schedules_by_type

    weekly_schedules = travel_pattern_service_schedules[:weekly_schedules].map(&:service_schedule)
    extra_service_schedules = travel_pattern_service_schedules[:extra_service_schedules].map(&:service_schedule)
    reduced_service_schedules = travel_pattern_service_schedules[:reduced_service_schedules].map(&:service_schedule)

    calendar = {}
    date = booking_window.earliest_booking.to_date
    end_date = booking_window.latest_booking.to_date
    
    while date <= end_date
      date_string = date.strftime('%Y-%m-%d')
      calendar[date_string] = {}

      reduced_sub_schedule = reduced_service_schedules.reduce(nil) do |sub_schedule, service_schedule|
        valid_start = service_schedule.start_date == nil || service_schedule.start_date < date
        valid_end = service_schedule.end_date == nil || service_schedule.end_date < date
        next unless valid_start && valid_end
        
        sub_schedule = service_schedule.service_sub_schedules.find do |sub_schedule|
          sub_schedule.calendar_date == date
        end

        break(sub_schedule) if sub_schedule
      end

      # Reduced schedules overwrite all other schedules so we can skip the rest of this iteration
      if reduced_sub_schedule
        calendar[date_string][:start_time] = reduced_sub_schedule.start_time
        calendar[date_string][:end_time] = reduced_sub_schedule.end_time
        date += 1.day
        next
      end

      weekly_schedules = weekly_schedules.select do |service_schedule|
        valid_start = service_schedule.start_date == nil || service_schedule.start_date < date
        valid_end = service_schedule.end_date == nil || service_schedule.end_date < date
        valid_start && valid_end
      end

      weekly_sub_schedules = weekly_schedules.map(&:service_sub_schedules).flatten.select do |sub_schedule|
        sub_schedule.day == date.wday
      end

      extra_service_schedules = extra_service_schedules.select do |service_schedule|
        valid_start = service_schedule.start_date == nil || service_schedule.start_date < date
        valid_end = service_schedule.end_date == nil || service_schedule.end_date < date
        valid_start && valid_end
      end

      extra_service_sub_schedules = extra_service_schedules.map(&:service_sub_schedules).flatten.select do |sub_schedule|
        sub_schedule.calendar_date == date
      end

      sub_schedules = weekly_sub_schedules + extra_service_sub_schedules
      calendar[date_string][:start_time] = sub_schedules.min_by(&:start_time)&.start_time
      calendar[date_string][:end_time] = sub_schedules.max_by(&:end_time)&.end_time
      date += 1.day
    end

    return calendar
  end
end
