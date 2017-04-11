class Admin::ServicesController < Admin::AdminController

  include GeoKitchen
  include FareHelper

  before_action :find_service, except: [:create, :index]

  def index
    @services = Service.all.order(:id)
  end

  def destroy
    @service.destroy
    redirect_to admin_services_path
  end

  def create
  	@service = Service.create(service_params)
  	redirect_to admin_service_path(@service)
  end

  # If JSON is requested, search geography tables based on passed param
  def show
    @service.build_geographies # Build empty start_or_end_area, trip_within_area, etc. based on service type.
    @service.build_comments # Builds a comment for each available locale

    respond_to do |format|
      format.html
      format.json do
        @counties = County.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @zipcodes = Zipcode.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @cities = City.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @custom_geographies = CustomGeography.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        json_response = @counties + @zipcodes + @cities + @custom_geographies
        render json: json_response
      end
    end
  end

  def update
    puts "BEFORE PERMITTING PARAMS", params.ai
    # puts "AFTER PERMITTING PARAMS", service_params.ai

    @service.update_attributes(service_params)
    error_msgs = @service.errors.messages.values
    puts "ERRORS", @service.errors.ai
    flash[:danger] = error_msgs.join(' ') unless error_msgs.empty?

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

  def find_service
    @service = Service.find(params[:id])
  end

  def service_type
    (@service && @service.type) || (params[:service] && params[:service][:type])
  end

  def service_params
    # By default, views are packaging parameters under keys named based on the
    # service's class name. Here's we're transfering all of that under a generic
    # "service" parameter key.
    params[:service] = params.delete :transit if params.has_key? :transit
    params[:service] = params.delete :taxi if params.has_key? :taxi
    params[:service] = params.delete :paratransit if params.has_key? :paratransit

    # Package fare params if fare_structure key is present
    FareParamPackager.new(params[:service]).package if params[:service].has_key?(:fare_structure)

    # Construct permitted parameters array based on Service Type
    permitted_params = base_permitted_params
    permitted_params += FareParamPermitter.new(params[:service]).permit
    permitted_params += transit_params if service_type == "Transit"
    permitted_params += paratransit_params if service_type == "Paratransit"
    permitted_params += taxi_params if service_type == "Taxi"

    # Permit the allowed parameters
  	params.require(:service).permit(permitted_params)
  end

  def base_permitted_params
    [
      :name, :type, :logo,
      :url, :email, :phone,
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
    ]
  end

  def taxi_params
    [
      {accommodation_ids: []},
      :taxi_fare_finder_id,
      trip_within_area_attributes: [:recipe]
    ]
  end
end
