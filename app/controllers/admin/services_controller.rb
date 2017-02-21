class Admin::ServicesController < Admin::AdminController

  def index
    @services = Service.all.order(:id)
  end

  def destroy
    @service = Service.find(params[:id])
    @service.destroy
    redirect_to admin_services_path
  end

  def create
    puts "CREATE", params.ai
  	Service.create!(service_params)
  	redirect_to admin_services_path
  end

  def show
    @service = Service.find(params[:id])
    @service
  end

  private

  def service_params
  	params.require(:service).permit(:name)
  end

end
