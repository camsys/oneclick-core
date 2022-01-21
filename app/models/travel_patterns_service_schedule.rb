class TravelPatternsServiceSchedule < ApplicationRecord
  scope :ordered, -> {joins(service: :agency).order("agencies.name")}
  scope :for_all_agencies, -> {all}
  scope :for_oversight_agency, -> {current_user.currently_oversight? ? where(service: current_user.current_agency.service_oversight_agency.pluck(:service_id)) : nil}
  scope :for_transport_agency, -> {current_user.currently_transportation? ? where(service: current_user.current_agency.services) : nil}

  belongs_to :service
  belongs_to :travel_patterns_service_schedule_type
  has_many :travel_patterns_schedule

  validates :name, presence: true, uniqueness: true
end
