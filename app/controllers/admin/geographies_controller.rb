class Admin::GeographiesController < Admin::AdminController

  def index
    @counties = County.all.order(:state)
  end

  def upload_counties
    uploader = ShapefileUploader.new(params[:geographies][:file], geo_type: :county)
    uploader.load
    flash[:danger] = uploader.errors.join(' ') if uploader.errors
    redirect_to admin_geographies_path
  end

end
