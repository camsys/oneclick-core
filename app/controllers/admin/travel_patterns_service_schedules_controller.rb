class Admin::TravelPatternsServiceSchedulesController < Admin::AdminController
  def index
    @service_schedules = get_service_schedules_for_current_user
  end

  def show

  end

  def create

  end

  def update

  end

  def destroy

  end

  private

  def get_service_schedules_for_current_user
    if current_user.superuser?
      TravelPatternsServiceSchedule.for_all_agencies.ordered
    elsif current_user.currently_oversight?
      TravelPatternsServiceSchedule.for_oversight_agency.ordered
    elsif current_user.currently_transportation?
      TravelPatternsServiceSchedule.for_transport_agency.order("name desc")
    end
  end
end