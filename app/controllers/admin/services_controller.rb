class Admin::ServicesController < Admin::AdminController

  include GeoKitchen
  include FareHelper
  include RemoteFormResponder

  attr_accessor :test_var
  load_and_authorize_resource # Loads and authorizes @service/@services instance variable

  def index
    always_unaffiliated_services = Service.where(type: [:Uber,:Lyft,:Taxi])
    # NOTE: Includes unaffiliated Services by default
    if current_user.superuser?
      @services
    elsif current_user.currently_oversight?
      oa = current_user.staff_agency
      @services = always_unaffiliated_services + Service.with_oversight_agency(oa).order(agency_id: :desc)
    elsif current_user.currently_transportation?
      @services = always_unaffiliated_services+Service.where(agency_id: current_user.current_agency.id)
      # otherwise the current user is probably transportation staff
    else
      @services = always_unaffiliated_services+Service.where(agency_id: current_user.staff_agency.id)
    end
  end

  def destroy
    @service.archive # Makes service invisible in default scope
    redirect_to admin_services_path
  end

  def create
    # If the user is a transit agency admin then automatically assign its oversight agency
    os_params = oversight_params
    oversight_agency_id = os_params[:oversight_agency_id]
    transportation_agency_id = os_params[:transportation_agency_id]
    # Assign the transportation agency based on the passed in id
    @service.agency = TransportationAgency.find_by(id:transportation_agency_id)
  	if @service.update_attributes(service_params)
      if oversight_agency_id != '' && !current_user.superuser?
        ServiceOversightAgency.create(oversight_agency_id: oversight_agency_id, service_id: @service.id)
      elsif current_user.superuser?
        ServiceOversightAgency.create(oversight_agency_id: @service.agency&.agency_oversight_agency&.oversight_agency&.id, service_id: @service.id)
      end
      redirect_to admin_service_path(@service)
    else
      present_error_messages(@service)
      redirect_to admin_services_path
    end
  end

  def show
    @service.build_geographies # Build empty start_or_end_area, trip_within_area, etc. based on service type.
    # @service.build_comments # Builds a comment for each available locale
  end

  def update
    os_params = oversight_params
    @service.update_attributes(service_params)
    # If the service doesn't have a service oversight agency and has an agency assigned
    if @service.service_oversight_agency.nil? && !@service.agency.nil?
      ServiceOversightAgency.create(oversight_agency_id: @service.agency.agency_oversight_agency.oversight_agency_id, service_id: @service.id)
    # Else If the service doesn't have a service oversight agency and does not have an agency assigned
    elsif @service.service_oversight_agency.nil? && @service.agency.nil?
      ServiceOversightAgency.create(oversight_agency_id: os_params[:oversight_agency_id], service_id: @service.id)
    # Else If the service has a service oversight agency object, but no oversight agency and no transportation agency
    elsif @service.service_oversight_agency.oversight_agency.nil? && @service.agency.nil?
      @service.service_oversight_agency.update(oversight_agency_id: os_params[:oversight_agency_id])
    # Else update the service's oversight agency with the agency
    else
      @service.service_oversight_agency.update(oversight_agency_id:@service.agency&.agency_oversight_agency&.oversight_agency_id)
    end
    #Force the updated attribute to update, even if only child objects were changeg (e.g., Schedules, Accomodtations, etc.)
    @service.update_attributes({updated_at: Time.now}) 
    present_error_messages(@service)
    # If a partial_path parameter is set, serve back that partial
    respond_with_partial_or do
      flash[:success] = "#{@service.name} updated successfully."
      redirect_to admin_service_path(@service)
    end    
  end

  private

  def service_type
    (@service && @service.type) || (params[:service] && params[:service][:type])
  end

  def oversight_params
    params.delete(:oversight)
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
      :fare_structure,
      :booking_api,
      :max_age,
      :min_age,
      {accommodation_ids: []},
      {eligibility_ids: []},
      {purpose_ids: []},
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


end
