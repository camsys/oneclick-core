class Admin::TravelPatternsController < Admin::AdminController
  load_resource only: [:show, :new, :edit, :update, :destroy]
  before_action :load_child_resources, only: [:show, :edit]

  def index
    @travel_patterns = get_travel_patterns_for_current_user
  end

  def show
    @agency = @travel_pattern.agency
  end

  def new
    @travel_pattern.agency = Agency.find(params[:agency_id])
    @agency = @travel_pattern.agency
  end

  def create
    travel_pattern_created = false
    error_message = nil

    TravelPattern.transaction do
      begin
        if TravelPattern.create(travel_pattern_params)
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
    @agency = @travel_pattern.agency
  end

  def update
    travel_pattern_updated = false
    error_message = nil

    TravelPattern.transaction do
      begin
        if @travel_pattern.update(travel_pattern_params)
          travel_pattern_updated = true
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
    if @travel_pattern.destroy
      redirect_to admin_travel_patterns_path
    end
  end

  private

  def get_travel_patterns_for_current_user
    TravelPattern.for_user(current_user)
  end

  def travel_pattern_params
    permitted_params = params.require(:travel_pattern).permit(
      :agency_id, 
      :name,
      :description,
      :origin_zone_id,
      :destination_zone_id,
      :allow_reverse_sequence_trips,
      :booking_window_id,
      travel_pattern_service_schedules_attributes: [ :id, :service_schedule_id, :_destroy ],
      travel_pattern_purposes_attributes: [ :id, :purpose_id, :_destroy ],
      travel_pattern_funding_sources_attributes: [ :id, :funding_source_id, :_destroy ],
    )

    permitted_params[:travel_pattern_service_schedules_attributes]&.values&.each_with_index do |schedule, index|
      schedule[:priority] = index + 1 unless schedule[:service_schedule_id].blank?;
    end

    permitted_params
  end

  def load_child_resources
    @travel_pattern_service_schedules = @travel_pattern.travel_pattern_service_schedules
                                                       .includes(:service_schedule)
                                                       .joins(:service_schedule)
                                                       .merge(ServiceSchedule.order(:name))
    @travel_pattern_service_schedules += [@travel_pattern_service_schedules.build]

    @travel_pattern_purposes = @travel_pattern.travel_pattern_purposes
                                              .includes(:purpose)
                                              .joins(:purpose)
                                              .merge(Purpose.order(:name))
    @travel_pattern_purposes += [@travel_pattern_purposes.build]

    @travel_pattern_funding_sources = @travel_pattern.travel_pattern_funding_sources
                                                     .includes(:funding_source)
                                                     .joins(:funding_source)
                                                     .merge(FundingSource.order(:name))
    @travel_pattern_funding_sources += [@travel_pattern_funding_sources.build]
  end
end
