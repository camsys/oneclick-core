class Admin::ServicesController < Admin::AdminController

  include GeoKitchen
  include FareHelper

  load_and_authorize_resource # Loads and authorizes @service/@services instance variable

  def index
  end

  def destroy
    @service.archive # Makes service invisible in default scope
    redirect_to admin_services_path
  end

  def create
    @service.agency = current_user.staff_agency # Assign the service to the user's staff agency
  	if @service.update_attributes(service_params)
      redirect_to admin_service_path(@service)
    else
      present_error_messages(@service)
      redirect_to admin_services_path
    end
  end

  def show
    @service.build_geographies # Build empty start_or_end_area, trip_within_area, etc. based on service type.
    @service.build_comments # Builds a comment for each available locale
  end

  def update
    @service.update_attributes(service_params)
    present_error_messages(@service)

    # If a partial_path parameter is set, serve back that partial
    if params[:partial_path]
      respond_to do |format|
        format.html do
          render template: params[:partial_path], layout: '/layouts/_panel'
        end
        format.js do
          render template: params[:partial_path], layout: '/layouts/_panel'
        end
      end
    else
      respond_to do |format|
        format.html do
          redirect_to admin_service_path(@service)
        end
      end
    end
  end

  private

  def service_type
    (@service && @service.type) || (params[:service] && params[:service][:type])
  end

  def service_params
    # By default, views are packaging parameters under keys named based on the
    # service's class name. Here's we're transfering all of that under a generic
    # "service" parameter key.
    params[:service] = params.delete :transit if params.has_key? :transit
    params[:service] = params.delete :taxi if params.has_key? :taxi
    params[:service] = params.delete :uber if params.has_key? :uber
    params[:service] = params.delete :paratransit if params.has_key? :paratransit

    # Package fare params if fare_structure key is present
    FareParamPackager.new(params[:service]).package if params[:service].has_key?(:fare_structure)

    # Construct permitted parameters array based on Service Type
    permitted_params = base_permitted_params
    permitted_params += transit_params if service_type == "Transit"
    permitted_params += paratransit_params if service_type == "Paratransit"
    permitted_params += taxi_params if service_type == "Taxi"
    permitted_params += uber_params if service_type == "Uber"

    # Permit the allowed parameters
  	params.require(:service).permit(permitted_params)
  end

  def base_permitted_params
    [
      :name, :type, :logo,
      :url, :email, :phone,
      :agency_id, :published,
      comments_attributes: [:id, :comment, :locale]
    ]
  end

  def transit_params
    [:gtfs_agency_id]
  end

  def paratransit_params
    [
      {accommodation_ids: []},
      {eligibility_ids: []},
      {purpose_ids: []},
      start_or_end_area_attributes: [:recipe],
      trip_within_area_attributes: [:recipe],
      schedules_attributes: [:id, :day, :start_time, :end_time, :_destroy]
    ] + FareParamPermitter.new(params[:service]).permit
  end

  def taxi_params
    [
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


end
