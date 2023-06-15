class Admin::ServicesController < Admin::AdminController

  include GeoKitchen
  include FareHelper
  include RemoteFormResponder

  attr_accessor :test_var
  load_and_authorize_resource # Loads and authorizes @service/@services instance variable

  before_action :load_travel_patterns, only: [:show, :update]

  def index
    @services = get_services_for_current_user
    @oversight_agencies = current_user.accessible_oversight_agencies.length > 0 ?
                            current_user.accessible_oversight_agencies.order(:name) :
                            Agency.querify([current_user.staff_agency&.agency_oversight_agency&.oversight_agency]).order(:name)
    @transportation_agencies = current_user.get_transportation_agencies_for_user.order(:name)
    @default_agency = get_default_tranpsortation_agency_selection
  end

  def destroy
    @service.archive # Makes service invisible in default scope
    redirect_to admin_services_path
  end

  # Service create fail conditions:
  # - missing service name
  # - missing service type
  # - missing service oversight agency
  # - bad combination of service agency and oversight agency
  #   - e.g if Rabbit is overseen by Penn DOT but I pick UTA as the oversight,
  #   ...then service create will fail as that's an invalid combination of agencies
  def create
    # If the user is a transit agency admin then automatically assign its oversight agency
    os_params = oversight_params
    s_params = service_params
    oversight_agency_id = os_params[:oversight_agency_id]
    transportation_agency_id = s_params[:agency_id]
    # if oversight is empty/ a bad combo of oversight, then redirect
    is_not_included = !Service::TAXI_SERVICES.include?(s_params[:type]) && validate_agencies_choices(oversight_agency_id,transportation_agency_id)


  	if @service.errors.empty? && @service.update_attributes(service_params)
      ServiceOversightAgency.create(oversight_agency_id: oversight_agency_id, service_id: @service.id)
      redirect_to admin_service_path(@service)
    else
      present_error_messages(@service)
      redirect_to admin_services_path
    end
  end

  def show
    @service.build_geographies # Build empty start_or_end_area, trip_within_area, etc. based on service type.
    # @service.build_comments # Builds a comment for each available locale
    #
    accessible_oversight_agencies = current_user.accessible_oversight_agencies.length > 0 ?
                            current_user.accessible_oversight_agencies.to_a :
                            [current_user.staff_agency&.agency_oversight_agency&.oversight_agency]
    accessible_transportation_agencies = current_user.get_transportation_agencies_for_user.to_a
    @oversight_agencies = Agency.querify(accessible_oversight_agencies.concat([@service.service_oversight_agency&.oversight_agency])).order(:name)
    @transportation_agencies = Agency.querify(accessible_transportation_agencies.concat([@service&.agency])).order(:name)
  end

  # NOTE: the service view/ update page consists of several micro-forms that a user updates and submits
  # - when you submit a micro form, service#update is called
  # ...and on successful update, OCC responds with the updated micro-form,
  # ...and Turbolinks handles updating that specific form on the frontend
  def update
    os_params = oversight_params
    s_params = service_params
    # If occ gets a request to update the service's agencies, then perform the below:
    if os_params.present?
      oversight_agency_id = os_params[:oversight_agency_id]
      transportation_agency_id = s_params[:agency_id]
      validate_agencies_choices(oversight_agency_id,transportation_agency_id)

      # If the requested oversight and transit agencies are valid/ don't add an error to the
      # service record, then continue trying to update the service
      if @service.errors.empty?
        # update the existing service_oversight_agency if it's valid and exists
        if @service.service_oversight_agency.present?
          @service.service_oversight_agency.update(oversight_agency_id: oversight_agency_id)
        else
          ServiceOversightAgency.create(oversight_agency_id: oversight_agency_id,service_id: @service.id)
        end
        # Finally update service's assigned transportation agency
        # We update that last as oversight agency has higher precedence over
        # ...transit agency
        @service.update_attributes(agency_id: transportation_agency_id)
      end
    # else if no oversight_params then just update service attributes as normal
    else
      # ensure at least one travel pattern is assigned to the service before publishing (if in travel patterns config)
      if Config.dashboard_mode == "travel_patterns" &&
        ((s_params[:published] == "true" && @service.travel_pattern_services.count == 0) ||
        (s_params[:travel_pattern_services_attributes]&.reject{|k,v| v[:travel_pattern_id].blank?}&.values&.all?{|v| v[:_destroy] == "true"} && @service.published == true))
        @service.errors.add(:base, "Service cannot be published without at least one travel pattern assigned.")
      else
        @service.update_attributes(s_params)
      end
    end

    # Code to handle server response on update fail/ success including redirects
    # - present_error_messages needs to run before update_attributes otherwise the
    #   ...record errors gets cleared on update
    if @service.errors.empty?
      flash[:success] = "#{@service.name} updated successfully."
    else
      present_error_messages(@service)
    end
    #Force the updated attribute to update, even if only child objects were changed (e.g., Schedules, Accomodtations, etc.)
    @service.update_attributes({updated_at: Time.now})   

    # Respond with the micro-form
    respond_with_partial_or do
      redirect_to admin_service_path(@service)
    end    
  end

  private

  def get_default_tranpsortation_agency_selection
    if current_user.superuser? || current_user.currently_oversight? || (current_user.staff_agency.oversight? && current_user.current_agency.nil?)
      nil
    elsif current_user.currently_transportation?
      current_user.current_agency
    else
      current_user.staff_agency
    end
  end

  def get_services_for_current_user
    # NOTE: Includes unaffiliated Services by default
    if current_user.superuser?
      @services
    elsif current_user.currently_oversight?
      oa = current_user.staff_agency

      Service.with_oversight_agency(oa).order(agency_id: :desc)
    elsif current_user.currently_transportation?
      Service.where(agency_id: current_user.current_agency.id)
      # otherwise the current user is probably transportation staff
    elsif current_user.current_agency.nil? && current_user&.staff_agency&.oversight?
      # Return services with no transportation agency and oversight agency
      Service.where(agency_id: nil).select{|s| !s&.service_oversight_agency&.oversight_agency}
    else
      Service.where(agency_id: current_user.staff_agency.id)
    end
  end


  def service_type
    (@service && @service.type) || (params[:service] && params[:service][:type])
  end

  def oversight_params
    params.delete(:oversight)
  end

  # Validates oversight and transportation agency choice
  # - returns NULL, adds an error the the Service record if inputs are found
  #   ...to be an invalid combination
  def validate_agencies_choices(oversight_id, transportation_id)
    # If either are empty, or if the Service is a Taxi service, return false
    err_message = "Bad combination of Oversight Agency and Transportation Agency for #{@service.name}, did not perform service create/ update"
    is_empty = transportation_id&.empty?
    # if transportation id is empty, don't need to validate
    if is_empty
      return nil
    elsif oversight_id.empty? && transportation_id.present?
      @service.errors.add(:agency,"Oversight Agency empty for #{@service.name}, did not perform service create/ update")
    end

    oa = OversightAgency.find_by(id: oversight_id)
    ta  = TransportationAgency.find transportation_id

    associated_tas = oa&.agency_oversight_agency&.map{|aoa| aoa.transportation_agency}
    is_included = associated_tas&.include?(ta)

    unless is_included
      @service.errors.add(:agency,err_message)
    end
  end

  def service_params
    # By default, views are packaging parameters under keys named based on the
    # service's class name. Here's we're transfering all of that under a generic
    # "service" parameter key.
    params[:service] = params.delete :transit if params.has_key? :transit
    params[:service] = params.delete :taxi if params.has_key? :taxi
    params[:service] = params.delete :uber if params.has_key? :uber
    params[:service] = params.delete :lyft if params.has_key? :lyft
    params[:service] = params.delete :paratransit if params.has_key? :paratransit

    # Package fare params if fare_structure key is present
    FareParamPackager.new(params[:service]).package if params[:service].has_key?(:fare_structure)

    # Construct permitted parameters array based on Service Type
    permitted_params = base_permitted_params
    permitted_params += transit_params if service_type == "Transit"
    permitted_params += paratransit_params if service_type == "Paratransit"
    permitted_params += taxi_params if service_type == "Taxi"
    permitted_params += uber_params if service_type == "Uber"
    permitted_params += lyft_params if service_type == "Lyft"
    permitted_params += travel_pattern_services_params if Config.dashboard_mode == "travel_patterns"

    # Permit the allowed parameters
  	params.require(:service).permit(permitted_params)
  end

  def base_permitted_params
    [
      :name, :type, :logo,
      :url, :email, :phone,
      :agency_id, :published, :updated_at
    ] + description_params
  end

  def transit_params
    [:gtfs_agency_id, :fare_structure] + FareParamPermitter.new(params[:service]).permit
  end

  def paratransit_params
    [
      :gtfs_agency_id,
      :fare_structure,
      :booking_api,
      :max_age,
      :min_age,
      :eligible_max_age,
      :eligible_min_age,
      {accommodation_ids: []},
      {eligibility_ids: []},
      {purpose_ids: []},
      start_area_attributes: [:recipe],
      end_area_attributes: [:recipe],
      start_or_end_area_attributes: [:recipe],
      trip_within_area_attributes: [:recipe],
      schedules_attributes: [:id, :day, :start_time, :end_time, :_destroy]
    ] + 
    FareParamPermitter.new(params[:service]).permit + 
    ServiceBookingParamPermitter.new(params[:service]).permit
  end

  def taxi_params
    [
      :fare_structure,
      {accommodation_ids: []},
      start_area_attributes: [:recipe],
      end_area_attributes: [:recipe],
      start_or_end_area_attributes: [:recipe],
      trip_within_area_attributes: [:recipe]
    ] + FareParamPermitter.new(params[:service]).permit
  end

  def uber_params
    [
      {accommodation_ids: []},
      trip_within_area_attributes: [:recipe]
    ]
  end

  def lyft_params
    [
      {accommodation_ids: []},
      trip_within_area_attributes: [:recipe]
    ]
  end
  
  # returns an array of localized description param names
  def description_params
    I18n.available_locales.map { |l| "#{l}_description".to_sym }
  end

  def travel_pattern_services_params
    [travel_pattern_services_attributes: [ :id, :travel_pattern_id, :_destroy ]]
  end

  def load_travel_patterns
    @travel_pattern_services = @service.travel_pattern_services
                                   .includes(:travel_pattern)
                                   .joins(:travel_pattern)
                                   .merge(TravelPattern.order(:name))
  end

end
