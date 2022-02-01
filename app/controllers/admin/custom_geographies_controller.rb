class Admin::CustomGeographiesController < Admin::AdminController
  authorize_resource :geography_record, parent: false

  def index
    @geographies = get_geographies_for_user
  end

  def create
    # agency = Agency.find_by(id: params[:geographies][:agency])
    # NOTE: THE BELOW IS TEMPORARY AND SHOULD BE REMOVED ONCE WE FULLY IMPLEMENT
    # AGENCY SELECTION/ PERMISSIONS AND TRAVEL PATTERNS
    agency = TransportationAgency.first.id

    # TODO: ADD KML FILE UPLOAD HANDLING
    uploader = ShapefileUploader.new(params[:geographies][:shapefile],
                                     name: params[:geographies][:name]&.titleize,
                                     geo_type: :custom_geography,
                                     column_mappings: {name: 'NAME'})
    uploader.load
    present_error_messages(uploader)
    redirect_to admin_custom_geographies_path
  end

  private
  def custom_geography_params
    params.require(:custom_geography).permit(
      :agency,
      :id
    )
  end

  def get_geographies_for_user
    if current_user.superuser?
      CustomGeography.all.order(:name)
    elsif current_user.transportation_staff? || current_user.transportation_admin?
      CustomGeography.where(agency_id: current_user.staff_agency.id).order(:name)
    elsif current_user.currently_oversight?
      tas = current_user.staff_agency.agency_oversight_agency.map {|aoa| aoa.transportation_agency.id}
      CustomGeography.where(agency_id: tas).order(:name)
    elsif current_user.currently_transportation?
      CustomGeography.where(agency_id: current_user.current_agency.id).order(:name)
    elsif current_user.staff_agency.oversight? && current_user.current_agency.nil?
      CustomGeography.where(agency_id: nil).order(:name)
    end
  end
end
