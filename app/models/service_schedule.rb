class ServiceSchedule < ApplicationRecord
  scope :ordered, -> {joins(service: :agency).order("agencies.name")}
  scope :for_superuser, -> {all}
  scope :for_oversight_user, -> (user) {where(service: user.current_agency.service_oversight_agency.pluck(:service_id))}
  scope :for_transport_user, -> (user) {where(service: user.current_agency.services)}

  belongs_to :service
  belongs_to :service_schedule_type
  has_many :service_sub_schedules, dependent: :destroy

  attr_accessor :agency
  accepts_nested_attributes_for :service_sub_schedules

  validates :name, presence: true, uniqueness: true

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
