class Admin::ServiceSchedulesController < Admin::AdminController
  def index
    @service_schedules = get_service_schedules_for_current_user
  end

  def show
    @service_schedule = ServiceSchedule.find(params[:id])
    @agency = @service_schedule.service.agency
  end

  def new
    @service_schedule = ServiceSchedule.new
    @agency = current_user.current_agency
  end

  def create
    service_schedule_params = params.require(:service_schedule).except(:service_sub_schedules_attributes).permit!
    sub_schedule_params = params.require(:service_schedule).require(:service_sub_schedules_attributes)
    schedule_created = false
    ServiceSchedule.transaction do
      begin
        if @service_schedule = ServiceSchedule.create(service_schedule_params)
          sub_schedule_params.each do |s|
            unless s[:_destroy] == "1"
              sub_schedule = ServiceSubSchedule.new(s.except(:_destroy).permit!)
              sub_schedule.service_schedule = @service_schedule
              unless sub_schedule.save!
                raise ActiveRecord::Rollback
              end
            end
          end
          schedule_created = true
        end
      rescue => e
        raise ActiveRecord::Rollback
      end
    end

    if schedule_created
      flash[:success] = "New Service Schedule successfully created."
      redirect_to admin_service_schedules_path
    else
      flash[:danger] = "There was an issue creating the Service Schedule."
      redirect_to new_admin_service_schedule_path
    end
  end

  def edit
    @service_schedule = ServiceSchedule.find(params[:id])
    @agency = @service_schedule.service.agency
  end

  def update
    @service_schedule = ServiceSchedule.find(params[:id])
    service_schedule_params = params.require(:service_schedule).except(:service_sub_schedules_attributes).permit!
    sub_schedule_params = params.require(:service_schedule).require(:service_sub_schedules_attributes)
    schedule_updated = false
    ServiceSchedule.transaction do
      begin
        if @service_schedule.update(service_schedule_params)
          sub_schedule_params.each do |s|
            if s[:_destroy] == "true"
              unless s[:id].blank?
                unless ServiceSubSchedule.find(s[:id]).destroy
                  raise ActiveRecord::Rollback
                end
              end
            else
              if s[:id].blank?
                sub_schedule = ServiceSubSchedule.new(s.except(:_destroy).permit!)
                sub_schedule.service_schedule = @service_schedule
                unless sub_schedule.save!
                  raise ActiveRecord::Rollback
                end
              else
                unless ServiceSubSchedule.find(s[:id]).update(s.except(:_destroy).permit!)
                  raise ActiveRecord::Rollback
                end
              end
            end
          end
          schedule_updated = true
        end
      rescue => e
        raise ActiveRecord::Rollback
      end
    end

    if schedule_updated
      flash[:success] = "Service Schedule successfully updated."
      redirect_to admin_service_schedules_path
    else
      flash[:danger] = "There was an issue updating the Service Schedule."
      redirect_to edit_admin_service_schedule_path(id: @service_schedule.id)
    end
  end

  def destroy
    service_schedule = ServiceSchedule.find(params[:id])
    service_schedule.destroy
    redirect_to admin_service_schedules_path
  end

  private

  def get_service_schedules_for_current_user
    ServiceSchedule.for_user(current_user)
  end
end