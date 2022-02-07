class Admin::ServiceSchedulesController < Admin::AdminController
  def index
    @service_schedules = get_service_schedules_for_current_user
  end

  def show

  end

  def new

  end

  def create

  end

  def edit

  end

  def update

  end

  def destroy
    service_schedule = ServiceSchedule.find(params[:id])
    service_schedule.destroy
    redirect_to admin_service_schedules_path
  end

  private

  def get_service_schedules_for_current_user
    if current_user.superuser?
      ServiceSchedule.for_all_agencies.ordered
    elsif current_user.currently_oversight?
      ServiceSchedule.for_oversight_agency.ordered
    elsif current_user.currently_transportation?
      ServiceSchedule.for_transport_agency.order("name desc")
    end
  end
end