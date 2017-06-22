class Admin::GeographiesController < Admin::AdminController

  def index
    @counties = County.all.order(:state, :name)
    @cities = City.all.order(:state, :name)
    @zipcodes = Zipcode.all.order(:name)
    @custom_geographies = CustomGeography.all.order(:name)
  end

  def upload_counties
    uploader = ShapefileUploader.new(params[:geographies][:file], geo_type: :county)
    uploader.load
    flash[:danger] = uploader.errors.join(' ') unless uploader.errors.empty?
    redirect_to admin_geographies_path
  end

  def upload_cities
    uploader = ShapefileUploader.new(params[:geographies][:file], geo_type: :city)
    uploader.load
    flash[:danger] = uploader.errors.join(' ') unless uploader.errors.empty?
    redirect_to admin_geographies_path
  end

  def upload_zipcodes
    uploader = ShapefileUploader.new(params[:geographies][:file],
      geo_type: :zipcode,
      column_mappings: {name: 'ZCTA5CE10'})
    uploader.load
    flash[:danger] = uploader.errors.join(' ') unless uploader.errors.empty?
    redirect_to admin_geographies_path
  end

  def upload_custom_geographies
    uploader = ShapefileUploader.new(params[:geographies][:file],
      geo_type: :custom_geography,
      column_mappings: {name: 'NAME'})
    uploader.load
    flash[:danger] = uploader.errors.join(' ') unless uploader.errors.empty?
    redirect_to admin_geographies_path
  end
  
  # Serves JSON responses to geography searches to enable autocomplete
  def autocomplete
    respond_to do |format|
      format.json do
        @counties = County.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @zipcodes = Zipcode.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @cities = City.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @custom_geographies = CustomGeography.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        json_response = @counties + @zipcodes + @cities + @custom_geographies
        render json: json_response
      end
    end
  end

end
