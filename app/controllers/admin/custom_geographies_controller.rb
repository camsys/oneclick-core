class Admin::CustomGeographiesController < Admin::AdminController
  authorize_resource :geography_record, parent: false

  def index
    @geographies = current_user.get_geographies_for_user
  end

  def create
    # TODO: ADD KML FILE UPLOAD HANDLING
    uploader = ShapefileUploader.new(params[:geographies][:shapefile],
                                     name: params[:geographies][:name]&.titleize,
                                     agency: params[:geographies][:agency],
                                     geo_type: :custom_geography,
                                     column_mappings: {name: 'NAME'})
    uploader.load
    present_error_messages(uploader)
    # redirect with query params if uploader errors is empty custom geography created
    redirect_to admin_custom_geographies_path(uploader.errors.empty? ? { selected: uploader.custom_geo } : {})
  end

  private
  def custom_geography_params
    params.require(:custom_geography).permit(
      :agency,
      :id
    )
  end
end
