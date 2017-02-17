class Admin::ServicesController < Admin::AdminController

  def index
    @services = Service.all.order(:id)
  end

end
