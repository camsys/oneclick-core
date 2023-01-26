class ServiceSchedule < ApplicationRecord
  scope :ordered, -> {joins(:agency).order("agencies.name, service_schedules.name")}
  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> (user) {where(agency: user.current_agency.agency_oversight_agency.pluck(:transportation_agency_id).concat([user.current_agency.id]))}
  scope :for_current_transport_user, -> (user) {where(agency: user.current_agency)}
  scope :for_transport_user, -> (user) {where(agency: user.staff_agency)}
  scope :weekly_schedules, -> { joins(:service_schedule_type).merge(ServiceScheduleType.weekly_schedule_type) }
  scope :calendar_date_schedules, -> { joins(:service_schedule_type).merge(ServiceScheduleType.calendar_date_schedule_type) }
  scope :for_date, -> (date) do
    joins(:service_sub_schedules)
      .where(arel_table[:start_date].lteq(date).or(arel_table[:start_date].eq(nil)))
      .where(arel_table[:end_date].gteq(date).or(arel_table[:end_date].eq(nil)))
      .merge(ServiceSubSchedule.for_date(date))
  end

  belongs_to :agency
  belongs_to :service_schedule_type
  has_many :service_sub_schedules, dependent: :destroy
  has_many :travel_pattern_service_schedules, dependent: :restrict_with_error
  has_many :travel_patterns, through: :travel_pattern_service_schedules

  attr_accessor :sub_schedule_calendar_dates
  attr_accessor :sub_schedule_calendar_times
  accepts_nested_attributes_for :service_sub_schedules

  validates :service_schedule_type, presence: true
  validates :name, presence: true, uniqueness: {scope: :agency_id}
  validate :end_date_after_start_date

  delegate :is_a_weekly_schedule?, :is_a_calendar_date_schedule?, to: :service_schedule_type

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

  def end_date_after_start_date
    unless end_date.blank? || start_date.blank?
      if end_date < start_date
        errors.add :end_date, "must be after start date"
      end
    end
  end
end
