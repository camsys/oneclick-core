class Admin::ServicesController < Admin::AdminController

  before_action :find_service, except: [:create, :index]

  def index
    @services = Service.all.order(:id)
  end

  def destroy
    @service.destroy
    redirect_to admin_services_path
  end

  def create
    puts "CREATE", params.ai
  	@service = Service.create(service_params)
  	redirect_to admin_service_path(@service)
  end

  def show
    @service
  end

  def update
    @service.update_attributes(service_params)
    redirect_to admin_service_path(@service)
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

    # Construct permitted parameters array based on Service Type
    permitted_params = [:name, :type, :logo, :url, :email, :phone]
    permitted_params += transit_params if service_type == "Transit"
    permitted_params += paratransit_params if service_type == "Paratransit"
    permitted_params += taxi_params if service_type == "Taxi"

    # Permit the allowed parameters
  	params.require(:service).permit(permitted_params)
  end

  def transit_params
    [:gtfs_agency_id]
  end

  def paratransit_params
    [{accommodation_ids: []}, {eligibility_ids: []}]
  end

  def taxi_params
    []
  end
end
