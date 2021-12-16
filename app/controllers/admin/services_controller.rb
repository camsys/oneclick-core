class Admin::ServicesController < Admin::AdminController

  include GeoKitchen
  include FareHelper
  include RemoteFormResponder

  attr_accessor :test_var
  load_and_authorize_resource # Loads and authorizes @service/@services instance variable

  def index
    @services = get_services_for_current_user
    @oversight_agencies = current_user.accessible_oversight_agencies.length > 0 ?
                            current_user.accessible_oversight_agencies.order(:name) :
                            Agency.querify([current_user.staff_agency&.agency_oversight_agency&.oversight_agency]).order(:name)
    @transportation_agencies = current_user.get_transportation_agencies_for_user.order(:name)
    @default_agency = get_default_tranpsortation_agency_selection
  end

  def destroy
    @service.archive # Makes service invisible in default scope
    redirect_to admin_services_path
  end

  def create
    # If the user is a transit agency admin then automatically assign its oversight agency
    os_params = oversight_params
    s_params = service_params
    oversight_agency_id = os_params[:oversight_agency_id]
    transportation_agency_id = s_params[:agency_id]
    # if oversight is empty/ a bad combo of oversight, then redirect
    is_not_included = validate_agencies_choices(oversight_agency_id,transportation_agency_id)

    if is_not_included == true
      present_error_messages(@service)
      redirect_to admin_services_path
      return
    end

    # else proceed
  	if @service.update_attributes(service_params)
      ServiceOversightAgency.create(oversight_agency_id: oversight_agency_id, service_id: @service.id)
      redirect_to admin_service_path(@service)
    else
      present_error_messages(@service)
      redirect_to admin_services_path
    end
  end

  def show
    @service.build_geographies # Build empty start_or_end_area, trip_within_area, etc. based on service type.
    # @service.build_comments # Builds a comment for each available locale
    #
    accessible_oversight_agencies = current_user.accessible_oversight_agencies.length > 0 ?
                            current_user.accessible_oversight_agencies.to_a :
                            [current_user.staff_agency&.agency_oversight_agency&.oversight_agency]
    accessible_transportation_agencies = current_user.get_transportation_agencies_for_user.to_a
    @oversight_agencies = Agency.querify(accessible_oversight_agencies.concat([@service.service_oversight_agency&.oversight_agency])).order(:name)
    @transportation_agencies = Agency.querify(accessible_transportation_agencies.concat([@service&.agency])).order(:name)
  end

  def update
    os_params = oversight_params
    s_params = service_params
    if os_params.present?
      oversight_agency_id = os_params[:oversight_agency_id]
      transportation_agency_id = s_params[:agency_id]
      is_not_included = validate_agencies_choices(oversight_agency_id,transportation_agency_id)
      # If agency combination is bad, then redirect with an error message
      if is_not_included == true
        respond_with_partial_or do
          redirect_to admin_service_path(@service)
        end
        return
        # Else if is_not_included is false/ valid combination of oversight agency and transportation agency
        # ... update the service_oversight_agency with the new oversight_agency
      elsif is_not_included == false || is_not_included.nil?
        # update the existing service_oversight_agency if it's valid and exists
        if @service.service_oversight_agency.present?
          @service.service_oversight_agency.update(oversight_agency_id: oversight_agency_id)
        else
          ServiceOversightAgency.create(oversight_agency_id: oversight_agency_id,service_id: @service.id)
        end
      end
      # Finally update service attributes(in this case agency_id)
      @service.update_attributes(s_params)
    # if no oversight_params then just update service attributes as normal
    else
      @service.update_attributes(s_params)
    end

    #Force the updated attribute to update, even if only child objects were changeg (e.g., Schedules, Accomodtations, etc.)
    @service.update_attributes({updated_at: Time.now}) 
    present_error_messages(@service)
    flash[:success] = "#{@service.name} updated successfully."

    # If a partial_path parameter is set, serve back that partial
    flash[:success] = "#{@service.name} updated successfully."

    # flash[:danger] = err_message unless err_message.nil?
    # What does respond_with_partial_or do that just extracting the block contents and using that doesn't?
    respond_with_partial_or do
      flash[:success] = "#{@service.name} updated successfully."
      redirect_to admin_service_path(@service)
    end    
  end

  private

  def get_default_tranpsortation_agency_selection
    if current_user.superuser? || current_user.currently_oversight? || (current_user.staff_agency.oversight? && current_user.current_agency.nil?)
      nil
    elsif current_user.currently_transportation?
      current_user.current_agency
    else
      current_user.staff_agency
    end
  end

  def get_services_for_current_user
    # NOTE: Includes unaffiliated Services by default
    if current_user.superuser?
      @services
    elsif current_user.currently_oversight?
      oa = current_user.staff_agency

      Service.with_oversight_agency(oa).order(agency_id: :desc)
    elsif current_user.currently_transportation?
      Service.where(agency_id: current_user.current_agency.id)
      # otherwise the current user is probably transportation staff
    elsif current_user.current_agency.nil? && current_user&.staff_agency&.oversight?
      # Return services with no transportation agency and oversight agency
      Service.where(agency_id:nil).select{|s| !s&.service_oversight_agency&.oversight_agency}
    else
      Service.where(agency_id: current_user.staff_agency.id)
    end
  end


  def service_type
    (@service && @service.type) || (params[:service] && params[:service][:type])
  end

  def oversight_params
    params.delete(:oversight)
  end

  # Validates oversight and transportation agency choice
  def validate_agencies_choices(oversight_id, transportation_id)
    # If either are empty, or if the Service is a Taxi service, return false
    err_message = "Bad combination of Oversight Agency and Transportation Agency for #{@service.name}, did not perform service create/ update"
    is_empty = transportation_id&.empty?
    # if transportation id is empty, don't need to validate
    if is_empty
      return nil
    elsif oversight_id.empty? && transportation_id.present?
      @service.errors.add(:agency,"Oversight Agency empty for #{@service.name}, did not perform service create/ update")
      return true # return true as validation fails if oversight agency is empty
    end

    oa = OversightAgency.find oversight_id
    ta  = TransportationAgency.find transportation_id

    associated_tas = oa.agency_oversight_agency.map{|aoa| aoa.transportation_agency}
    is_included = associated_tas.include?(ta)

    unless is_included
      @service.errors.add(:agency,err_message)
    end

    !is_included
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
