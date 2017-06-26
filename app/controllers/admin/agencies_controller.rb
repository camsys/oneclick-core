class Admin::AgenciesController < Admin::AdminController
  
  before_action :find_agency, except: [:create, :index]

  def index
    @agencies = Agency.all.order(:id)
  end
  
  def show
  end
  
  def create
    @agency = Agency.create(agency_params)
    redirect_to admin_agency_path(@agency)
  end
  
  def update
    @agency.update_attributes(agency_params)
    flash[:success] = "Agency Updated Successfully"
    redirect_to admin_agency_path(@agency)
  end
  
  def destroy
  end

  private

  def find_agency
    @agency = Agency.find(params[:id])
  end
  
  def agency_params
    if params.has_key?(:transportation_agency)
      params[:agency] = params.delete(:transportation_agency)
    elsif params.has_key?(:partner_agency)
      params[:agency] = params.delete(:partner_agency)
    end
    
    params.require(:agency).permit(
      :type,
      :name,
      :url,
      :phone,
      :email,
      :logo
    )
  end
  
end
