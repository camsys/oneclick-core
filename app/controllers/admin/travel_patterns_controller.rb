class Admin::TravelPatternsController < Admin::AdminController
  def index
    @travel_patterns = get_travel_patterns_for_current_user
  end

  def show
    @travel_pattern = TravelPattern.find(params[:id])
    @agency = @travel_pattern.agency
  end

  def new
    @travel_pattern = TravelPattern.new
    @agency = current_user.current_agency
  end

  def create
    travel_pattern_params = params.require(:travel_pattern).except(:travel_pattern_service_schedules_attributes).permit!
    if params[:travel_pattern][:travel_pattern_service_schedules_attributes]
      service_schedule_params = params.require(:travel_pattern).require(:travel_pattern_service_schedules_attributes)
    end

    travel_pattern_created = false
    error_message = nil

    TravelPattern.transaction do
      begin
        if @travel_pattern = TravelPattern.create(travel_pattern_params)
          if service_schedule_params
            service_schedule_params.values.each_with_index do |sched, i|
              unless sched[:_destroy] == "true"
                unless new_schedule = TravelPatternServiceSchedule.find_or_create_by(travel_pattern: @travel_pattern, service_schedule: sched[:service_schedule_id], priority: i + 1)
                  error_message = new_schedule.errors.full_messages.join("\n")
                  raise ActiveRecord::Rollback
                end
              end
            end
          end
          travel_pattern_created = true
        else
          error_message = @travel_pattern.errors.full_messages.join("\n")
          raise ActiveRecord::Rollback
        end
      rescue => e
        error_message ||= e.message
        raise ActiveRecord::Rollback
      end
    end

    if travel_pattern_created
      flash[:success] = "New Travel Pattern successfully created."
      redirect_to admin_travel_patterns_path
    else
      flash[:danger] = error_message
      redirect_to new_admin_travel_pattern_path
    end
  end

  def edit
    @travel_pattern = TravelPattern.find(params[:id])
    @agency = @travel_pattern.agency
  end

  def update
    @travel_pattern = TravelPattern.find(params[:id])

    travel_pattern_params = params.require(:travel_pattern).except(:travel_pattern_service_schedules_attributes).permit!

    if params[:travel_pattern][:travel_pattern_service_schedules_attributes]
      service_schedule_params = params.require(:travel_pattern).require(:travel_pattern_service_schedules_attributes)
    end

    travel_pattern_updated = false
    error_message = nil

    TravelPattern.transaction do
      begin
        if @travel_pattern.update(travel_pattern_params)
          if service_schedule_params
            service_schedule_params.values.each_with_index do |sched, i|
              if sched[:_destroy] == "true"
                if deleted_pattern = TravelPatternServiceSchedule.find_by(travel_pattern: @travel_pattern, service_schedule: sched[:service_schedule_id])
                  unless deleted_pattern.destroy
                    error_message = deleted_pattern.errors.full_messages.join("\n")
                    raise ActiveRecord::Rollback
                  end
                end
              else
                if existing_schedule = TravelPatternServiceSchedule.find_by(travel_pattern: @travel_pattern, service_schedule: sched[:service_schedule_id])
                  unless existing_schedule.update(priority: i + 1)
                    error_message = existing_schedule.errors.full_messages.join("\n")
                    raise ActiveRecord::Rollback
                  end
                else
                  unless new_schedule = TravelPatternServiceSchedule.create(travel_pattern: @travel_pattern, service_schedule: sched[:service_schedule_id], priority: i + 1)
                    error_message = new_schedule.errors.full_messages.join("\n")
                    raise ActiveRecord::Rollback
                  end
                end
              end
            end
          end
        else
          error_message = @travel_pattern.errors.full_messages.join("\n")
          raise ActiveRecord::Rollback
        end
      rescue => e
        error_message ||= e.message
        raise ActiveRecord::Rollback
      end
    end

    if travel_pattern_updated
      flash[:success] = "Travel Pattern successfully updated."
      redirect_to admin_travel_patterns_path
    else
      flash[:danger] = error_message
      redirect_to edit_admin_travel_pattern_path
    end
  end

  def destroy
    travel_pattern = TravelPattern.find(params[:id])
    if travel_pattern.destroy
      redirect_to admin_travel_patterns_path
    end
  end

  private

  def get_travel_patterns_for_current_user
    TravelPattern.for_user(current_user)
  end
end
