class Admin::AgenciesController < Admin::AdminController
  
  load_and_authorize_resource # Loads and authorizes @agency/@agencies instance variable

  def index
    @agencies = @agencies.order(:name)
  end
  
  def show
  end
  
  def create
    if @agency.update_attributes(agency_params)
      flash[:success] = "Agency Created Successfully"
      redirect_to admin_agency_path(@agency)
    else
      present_error_messages(@agency)
      redirect_to admin_agencies_path
    end
  end
  
  def update
    if @agency.update_attributes(agency_params)
      flash[:success] = "Agency Updated Successfully"
    else
      present_error_messages(@agency)
    end
    redirect_to admin_agency_path(@agency)
  end
  
  def destroy
    if @agency.destroy
      flash[:success] = "Agency Deleted Successfully"
    else
      flash[:warning] = "Agency could not be Deleted"
    end
    redirect_to admin_agencies_path
  end

  private
  
  def agency_params
    if params.has_key?(:transportation_agency)
      params[:agency] = params.delete(:transportation_agency)
    elsif params.has_key?(:partner_agency)
      params[:agency] = params.delete(:partner_agency)
    elsif params.has_key?(:oversight_agency)
      params[:agency] = params.delete(:oversight_agency)
    end
    
    params.require(:agency).permit(
      base_agency_params + description_params
    )
  end
  
  def base_agency_params
    [
      :type,
      :name,
      :url,
      :phone,
      :email,
      :logo,
      :published
    ]
  end
  
  # returns an array of localized description param names
  def description_params
    I18n.available_locales.map { |l| "#{l}_description".to_sym }
  end
  
end
