class Admin::CustomGeographiesController < Admin::AdminController
  load_and_authorize_resource

  def index
    @geographies = current_user.get_geographies_for_user
  end

  def create
    if params[:geographies][:shapefile]
      uploader = ShapefileUploader.new(params[:geographies][:shapefile],
                                       name: params[:geographies][:name]&.titleize,
                                       agency: params[:geographies][:agency],
                                       geo_type: :custom_geography,
                                       column_mappings: {name: 'NAME'})
      uploader.load
      flash[:warning] = uploader.warnings.to_sentence unless uploader.warnings.blank?
      present_error_messages(uploader)
    elsif params[:geographies][:kmlfile]
      uploader = KMLUploader.new(params[:geographies][:kmlfile],
                                     name: params[:geographies][:name]&.titleize,
                                     agency: params[:geographies][:agency],
                                     geo_type: :custom_geography,
                                     column_mappings: {name: 'NAME'})
      uploader.load
      flash[:warning] = uploader.warnings.to_sentence unless uploader.warnings.blank?
      present_error_messages(uploader)
    end

    # redirect with query params if uploader errors is empty custom geography created
    redirect_to admin_custom_geographies_path(uploader&.errors&.empty? ? { selected: uploader.custom_geo } : {})
  end

  def destroy
    if @custom_geography.destroy
      flash[:success] = "Custom Geography Deleted Successfully"
    else
      flash[:warning] = "Custom Geography could not be Deleted"
    end
    redirect_back(fallback_location: admin_path)
  end
end
