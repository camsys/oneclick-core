class ServiceSchedule < ApplicationRecord
  scope :ordered, -> {joins(:agency).order("agencies.name, service_schedules.name")}
  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> (user) {where(agency: user.current_agency.agency_oversight_agency.pluck(:transportation_agency_id))}
  scope :for_transport_user, -> (user) {where(agency: user.current_agency)}

  belongs_to :agency
  belongs_to :service_schedule_type
  has_many :service_sub_schedules, dependent: :destroy

  attr_accessor :sub_schedule_calendar_dates
  attr_accessor :sub_schedule_calendar_times
  accepts_nested_attributes_for :service_sub_schedules

  validates :name, presence: true, uniqueness: {scope: :agency_id}

  def self.for_user(user)
    if user.superuser?
      for_superuser.ordered
    elsif user.currently_oversight?
      for_oversight_user(user).ordered
    elsif user.currently_transportation?
      for_transport_user(user).order("name desc")
    else
      nil
    end
  end
end
