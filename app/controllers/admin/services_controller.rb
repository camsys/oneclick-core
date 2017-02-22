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
  	Service.create(service_params)
  	redirect_to admin_services_path
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

  def service_params
    params[:service] = params.delete :transit if params.has_key? :transit
    params[:service] = params.delete :taxi if params.has_key? :taxi
    params[:service] = params.delete :paratransit if params.has_key? :paratransit

  	params.require(:service).permit(:name, :type, :logo)
  end

end
