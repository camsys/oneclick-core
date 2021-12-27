class Admin::AgenciesController < Admin::AdminController
  
  load_and_authorize_resource # Loads and authorizes @agency/@agencies instance variable
  before_action :get_all_agency_types
  def index
    if current_user.superuser?
      @agencies = @agencies.order(:name)
    elsif current_user.currently_oversight?
      tas_id = AgencyOversightAgency.where(oversight_agency_id:current_user.current_agency.id).pluck(:transportation_agency_id)
      tas = TransportationAgency.where(id:tas_id)
      @agencies = Agency.querify([current_user.staff_agency].concat(tas))
    elsif current_user.currently_transportation?
      @agencies = Agency.querify([current_user.current_agency])
    elsif current_user.transportation_staff? || current_user.transportation_admin?
      @agencies = Agency.querify([current_user.staff_agency])
    else
      []
    end
  end
  
  def show
  end
  
  def create
    oversight_agency_id = oversight_params
    if oversight_agency_id == '' && AgencyType.find_by(name: "TransportationAgency").id.to_s == agency_params[:agency_type_id]
      flash[:danger] = "Agency creation failed! Oversight Agency cannot be empty!"
      redirect_to admin_agencies_path
      return
    end
    if @agency.update_attributes(agency_params)
      @agency.type = @agency.agency_type.name
      @agency.save
      AgencyOversightAgency.create(transportation_agency_id:@agency.id,
                                           oversight_agency_id: oversight_agency_id)
      flash[:success] = "Agency Created Successfully"
      redirect_to admin_agency_path(@agency)
    else
      present_error_messages(@agency)
      redirect_to admin_agencies_path
    end
  end
  
  def update
    oversight_agency_id = oversight_params
    if oversight_agency_id == ''
      flash[:danger] = "Agency update failed! Oversight Agency cannot be empty!"
      redirect_to admin_agencies_path
      return
    end
    if @agency.update_attributes(agency_params)
      if oversight_agency_id.present? && @agency.agency_oversight_agency
        @agency.agency_oversight_agency.update(oversight_agency_id: oversight_agency_id)
      elsif oversight_agency_id.present?
        AgencyOversightAgency.create(transportation_agency_id:@agency.id,oversight_agency_id: oversight_agency_id)
      end

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
  def get_all_agency_types
    if current_user.superuser?
      @agency_types = AgencyType.all
    else
      @agency_types = AgencyType.querify([AgencyType.find_by(name: 'TransportationAgency')])
    end
  end

  def oversight_params
    oversight = params&.delete(:oversight)
    oversight.present? && oversight["oversight_agency_id"]
  end

  def agency_params
    if params.has_key?(:transportation_agency)
      params[:agency] = params.delete(:transportation_agency)
    elsif params.has_key?(:partner_agency)
      params[:agency] = params.delete(:partner_agency)
    elsif params.has_key?(:oversight_agency)
      params[:agency] = params.delete(:oversight_agency)
    end
    #
    # if params[:agency][:type] == 'OversightAgency'
    #   params[:oversight].delete(:oversight_agency_id)
    # end

    params.require(:agency).permit(
      base_agency_params + description_params
    )
    # params.require(:oversight).permit(:oversight_agency_id)
  end

  def base_agency_params
    [
      :agency_type_id,
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
