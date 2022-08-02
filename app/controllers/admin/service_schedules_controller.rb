class Admin::ServiceSchedulesController < Admin::AdminController
  authorize_resource except: :index
  before_action :load_agency_from_params_or_user, only: [:new]

  def index
    @service_schedules = get_service_schedules_for_current_user
  end

  def show
    @service_schedule = ServiceSchedule.find(params[:id])

    @agency = @service_schedule.agency
    @schedule_type = @service_schedule.service_schedule_type
    @schedule_name = @service_schedule.name
    @schedule_description = @service_schedule.description
  end

  def new
    @service_schedule = ServiceSchedule.new
    @schedule_type = nil
    @schedule_name = params[:name]
    @schedule_description = params[:description]
  end

  def create
    service_schedule_params = params.require(:service_schedule).except(:service_sub_schedules_attributes, :sub_schedule_calendar_dates_attributes, :sub_schedule_calendar_times_attributes).permit!
    if params[:service_schedule][:service_sub_schedules_attributes]
      sub_schedule_params = params.require(:service_schedule).require(:service_sub_schedules_attributes)
    end
    if params[:service_schedule][:sub_schedule_calendar_dates_attributes]
      calendar_date_params = params.require(:service_schedule).require(:sub_schedule_calendar_dates_attributes)
    end

    if params[:service_schedule][:sub_schedule_calendar_times_attributes]
      calendar_time_params = params.require(:service_schedule).require(:sub_schedule_calendar_times_attributes)
    end
    schedule_created = false
    error_message = nil
    ServiceSchedule.transaction do
      begin
        unless @service_schedule = ServiceSchedule.new(service_schedule_params)
          error_message = @service_schedule.errors.full_messages.join("\n")
          raise ActiveRecord::Rollback
        end
        if service_schedule_params[:start_date] && service_schedule_params[:end_date]
          @service_schedule.start_date = service_schedule_params[:start_date].blank? ? nil : Date.parse(service_schedule_params[:start_date], "%Y/%m/%d")
          @service_schedule.end_date = service_schedule_params[:end_date].blank? ? nil : Date.parse(service_schedule_params[:start_date], "%Y/%m/%d")
        end

        if @service_schedule.save
          if sub_schedule_params
            sub_schedule_params.each do |s|
              unless s[:_destroy] == "true"

                unless sub_schedule = ServiceSubSchedule.new(s.except(:_destroy).permit!)
                  error_message = sub_schedule.errors.full_messages.join("\n")
                  raise ActiveRecord::Rollback
                end
                sub_schedule.service_schedule = @service_schedule
                unless sub_schedule.save!
                  schedule_created = false
                  error_message = sub_schedule.errors.full_messages.join("\n")
                  raise ActiveRecord::Rollback
                end
                schedule_created = true
              end
            end
          elsif calendar_date_params && calendar_time_params
            calendar_date_params.each do |d|
              unless d[:_destroy] == "true"
                date = d[:calendar_date]
                calendar_time_params.each do |t|
                  unless t[:_destroy] == "true"
                    start_time = t[:start_time]
                    end_time = t[:end_time]
                    unless sub_schedule = ServiceSubSchedule.create(service_schedule: @service_schedule, calendar_date: Date.parse(date, "%Y/%m/%d"), start_time: start_time, end_time: end_time)
                      schedule_created = false
                      error_message = sub_schedule.errors.full_messages.join("\n")
                      raise ActiveRecord::Rollback
                    end
                    unless sub_schedule.valid?
                      schedule_created = false
                      error_message = sub_schedule.errors.full_messages.join("\n")
                      raise ActiveRecord::Rollback
                    end
                    schedule_created = true
                  end
                end
              end
            end
          else
            error_message = "Service schedule must have at least one date and/or time defined"
            schedule_created = false
            raise ActiveRecord::Rollback
          end
        else
          error_message = @service_schedule.errors.full_messages.join("\n")
          raise ActiveRecord::Rollback
        end
      rescue => e
        error_message ||= e.message
        raise ActiveRecord::Rollback
      end
    end

    if schedule_created
      flash[:success] = "New Service Schedule successfully created."
      redirect_to admin_service_schedules_path
    else
      flash[:danger] = error_message
      redirect_to new_admin_service_schedule_path(agency_id: @service_schedule.agency_id, name: service_schedule_params[:name], description: service_schedule_params[:description])
    end
  end

  def edit
    @service_schedule = ServiceSchedule.find(params[:id])
    @agency = @service_schedule.agency
    @schedule_type = @service_schedule.service_schedule_type
    @schedule_name = @service_schedule.name
    @schedule_description = @service_schedule.description
  end

  def update
    # TODO: check that this works
    @service_schedule = ServiceSchedule.find(params[:id])
    old_type = @service_schedule.service_schedule_type

    service_schedule_params = params.require(:service_schedule).except(:service_sub_schedules_attributes, :sub_schedule_calendar_dates_attributes, :sub_schedule_calendar_times_attributes).permit!

    if params[:service_schedule][:service_sub_schedules_attributes]
      sub_schedule_params = params.require(:service_schedule).require(:service_sub_schedules_attributes)
    end
    if params[:service_schedule][:sub_schedule_calendar_dates_attributes]
      calendar_date_params = params.require(:service_schedule).require(:sub_schedule_calendar_dates_attributes)
    end

    if params[:service_schedule][:sub_schedule_calendar_times_attributes]
      calendar_time_params = params.require(:service_schedule).require(:sub_schedule_calendar_times_attributes)
    end
    schedule_updated = false
    error_message = nil
    ServiceSchedule.transaction do
      begin
        # Update main service schedule params
        if service_schedule_params[:start_date] && service_schedule_params[:end_date]
          @service_schedule.start_date = service_schedule_params[:start_date].blank? ? nil : Date.parse(service_schedule_params[:start_date], "%Y/%m/%d")
          @service_schedule.end_date = service_schedule_params[:start_date].blank? ? nil : Date.parse(service_schedule_params[:start_date], "%Y/%m/%d")
          unless @service_schedule.save
            error_message = @service_schedule.errors.full_messages.join("\n")
            raise ActiveRecord::Rollback
          end
        end
        if @service_schedule.update(service_schedule_params)
          unless @service_schedule.service_schedule_type == old_type
            unless deleted_schedules = @service_schedule.service_sub_schedules.destroy_all
              error_message = deleted_schedules.errors.full_messages.join("\n")
              raise ActiveRecord::Rollback
            end
          end

          # Editing Weekly pattern schedule type
          if @service_schedule.is_a_weekly_schedule? && sub_schedule_params
            sub_schedule_params.each do |s|
              if s[:_destroy] == "true"
                unless s[:id].blank?
                  unless deleted_schedule = ServiceSubSchedule.find_by(id: s[:id]).destroy
                    error_message = deleted_schedule.errors.full_messages.join("\n")
                    schedule_updated = false
                    raise ActiveRecord::Rollback
                  end
                  schedule_updated = true
                end
              else
                if s[:id].blank?
                  sub_schedule = ServiceSubSchedule.new(s.except(:_destroy).permit!)
                  sub_schedule.service_schedule = @service_schedule
                  unless sub_schedule.save!
                    schedule_updated = false
                    error_message = sub_schedule.errors.full_messages.join("\n")
                    raise ActiveRecord::Rollback
                  end
                  schedule_updated = true
                else
                  unless updated_schedule = ServiceSubSchedule.find_by(id: s[:id]).update(s.except(:_destroy).permit!)
                    schedule_updated = false
                    error_message = updated_schedule.errors.full_messages.join("\n")
                    raise ActiveRecord::Rollback
                  end
                  schedule_updated = true
                end
              end
            end

          # Editing Selected calendar dates schedule type
          elsif @service_schedule.is_a_calendar_date_schedule? && calendar_date_params && calendar_time_params
            # Parse calendar date inputs
            calendar_date_params.each do |d|
              date = d[:calendar_date]
              # Destroy existing sub-schedules with the previous object's calendar date (not input value) if removed from input field
              if d[:_destroy] == "true"
                unless d[:id].blank?
                  deleted = ServiceSubSchedule.where(service_schedule: @service_schedule, calendar_date: ServiceSubSchedule.find_by(id: d[:id])&.calendar_date)&.pluck(:calendar_date, :start_time, :end_time)
                  unless deleted_schedules = ServiceSubSchedule.where(service_schedule: @service_schedule, calendar_date: ServiceSubSchedule.find_by(id: d[:id])&.calendar_date).destroy_all
                    schedule_updated = false
                    error_message = deleted_schedules.errors.full_messages.join("\n")
                    raise ActiveRecord::Rollback
                  end
                  deleted.each do |d|
                    puts "deleted #{d}"
                  end
                  schedule_updated = true
                end
              else
                # Iterate through time inputs to create new sub-schedules for newly entered dates
                if d[:id].blank?
                  unless ServiceSubSchedule.find_by(service_schedule: @service_schedule, calendar_date: Date.parse(date, "%Y/%m/%d"))
                    calendar_time_params.each do |t|
                      unless t[:_destroy] == "true"
                        unless new_schedule = ServiceSubSchedule.create(service_schedule: @service_schedule, calendar_date: Date.parse(date, "%Y/%m/%d"), start_time: t[:start_time], end_time: t[:end_time])
                          schedule_updated = false
                          error_message = new_schedule.errors.full_messages.join("\n")
                          raise ActiveRecord::Rollback
                        end
                        unless new_schedule.valid?
                          schedule_updated = false
                          error_message = new_schedule.errors.full_messages.join("\n")
                          raise ActiveRecord::Rollback
                        end
                        puts "created #{date}, #{t[:start_time]}, #{t[:end_time]}"
                        schedule_updated = true
                      end
                    end
                  end
                # Update all existing sub-schedules with the previous object's date to the edited input value
                else
                  updated = ServiceSubSchedule.where(calendar_date: ServiceSubSchedule.find_by(id: d[:id])&.calendar_date)&.pluck(:calendar_date, :start_time, :end_time)
                  ServiceSubSchedule.where(service_schedule: @service_schedule, calendar_date: ServiceSubSchedule.find_by(id: d[:id])&.calendar_date).each do |s|
                    unless s.update(calendar_date: Date.parse(date, "%Y/%m/%d"))
                      schedule_updated = false
                      error_message = s.errors.full_messages.join("\n")
                      raise ActiveRecord::Rollback
                    end
                  end
                  updated.each do |u|
                    puts "updated #{u} -> #{date}"
                  end
                  schedule_updated = true
                end
              end
            end

            # Parse time inputs
            calendar_time_params.each do |t|
              # Destroy existing sub-schedules with the previous object's start and end times (not input values) if removed from input field
              if t[:_destroy] == "true"
                unless t[:id].blank?
                  deleted = ServiceSubSchedule.where(service_schedule: @service_schedule, start_time: ServiceSubSchedule.find_by(id: t[:id])&.start_time, end_time: ServiceSubSchedule.find_by(id: t[:id])&.end_time)&.pluck(:calendar_date, :start_time, :end_time)
                  unless deleted_schedules = ServiceSubSchedule.where(service_schedule: @service_schedule, start_time: ServiceSubSchedule.find_by(id: t[:id])&.start_time, end_time: ServiceSubSchedule.find_by(id: t[:id])&.end_time).destroy_all
                    schedule_updated = false
                    error_message = deleted_schedules.errors.full_messages.join("\n")
                    raise ActiveRecord::Rollback
                  end
                  deleted.each do |d|
                    puts "destroyed #{d}"
                  end
                  schedule_updated = true
                end
              else
                # Iterate through date inputs to create new sub-schedules for newly entered times
                if t[:id].blank?
                  calendar_date_params.each do |d|
                    unless d[:_destroy] == "true"
                      unless new_schedule = ServiceSubSchedule.find_or_create_by(service_schedule: @service_schedule, calendar_date: Date.parse(d[:calendar_date], "%Y/%m/%d"), start_time: t[:start_time], end_time: t[:end_time])
                        schedule_updated = false
                        error_message = new_schedule.errors.full_messages.join("\n")
                        raise ActiveRecord::Rollback
                      end
                      unless new_schedule.valid?
                        schedule_updated = false
                        error_message = new_schedule.errors.full_messages.join("\n")
                        raise ActiveRecord::Rollback
                      end
                      puts "created #{d[:calendar_date]}, #{t[:start_time]}, #{t[:end_time]}"
                      schedule_updated = true
                    end
                  end
                else
                  # Update all existing sub-schedules with the previous object's start and end times to the edited input values
                  updated = ServiceSubSchedule.where(start_time: ServiceSubSchedule.find_by(id: t[:id])&.start_time, end_time: ServiceSubSchedule.find_by(id: t[:id])&.end_time)&.pluck(:calendar_date, :start_time, :end_time)
                  ServiceSubSchedule.where(service_schedule: @service_schedule, start_time: ServiceSubSchedule.find_by(id: t[:id])&.start_time, end_time: ServiceSubSchedule.find_by(id: t[:id])&.end_time).each do |s|
                    unless s.update(start_time: t[:start_time], end_time: t[:end_time])
                      schedule_updated = false
                      error_message = s.errors.full_messages.join("\n")
                      raise ActiveRecord::Rollback
                    end
                  end
                  updated.each do |u|
                    puts "updated #{u} -> #{t[:start_time]}, #{t[:end_time]}"
                  end
                  schedule_updated = true
                end
              end
            end
          else
            schedule_updated = false
          end
        else
          error_message = @service_schedule.errors.full_messages.join("\n")
          raise ActiveRecord::Rollback
        end

        if @service_schedule.service_sub_schedules.count == 0
          error_message = "Service schedule must have at least one date and/or time defined"
          schedule_updated = false
          raise ActiveRecord::Rollback
        end
      rescue => e
        error_message ||= e.message
        raise ActiveRecord::Rollback
      end
    end

    if schedule_updated
      flash[:success] = "Service Schedule successfully updated."
      redirect_to admin_service_schedules_path
    else
      flash[:danger] = error_message
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