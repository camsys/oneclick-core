class Admin::OdZonesController < Admin::AdminController
  def index
    @od_zones = get_od_zones_for_current_user
  end

  def show
    @od_zone = OdZone.find(params[:id])
    @agency =  current_user.current_agency || Agency.first
  end

  def new
    @od_zone = OdZone.new
    @agency = current_user.current_agency || Agency.first
    @od_zone.agency = @agency
  end

  def create
    od_zone = OdZone.create(od_zone_params)

    if od_zone.valid?
      flash[:success] = "New O/D Zone successfully created."
      redirect_to admin_od_zones_path
    else
      flash[:danger] = "There was an issue creating the O/D Zone."
      redirect_to new_admin_od_zone_path
    end
  end

  def edit
    @od_zone = OdZone.find(params[:id])
    @agency = current_user.current_agency || Agency.first
    @od_zone.agency = @agency
  end

  def update
    @od_zone = OdZone.find(params[:id])

    if @od_zone.valid?
      flash[:success] = "O/D Zone successfully updated."
      redirect_to admin_od_zones_path
    else
      flash[:danger] = "There was an issue updating the O/D Zone."
      redirect_to edit_admin_od_zone_path(id: @od_zone.id)
    end
  end

  def destroy
    od_zone = OdZone.find(params[:id])
    od_zone.destroy
    redirect_to admin_od_zones_path
  end

  # Serves JSON responses to geography searches to enable autocomplete
  def autocomplete
    respond_to do |format|
      format.json do
        @counties = County.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @zipcodes = Zipcode.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @cities = City.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @custom_geographies = CustomGeography.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h}}
        @pois = Landmark.search(params[:term]).limit(10).map {|g| {label: g.to_s, value: GeoIngredient.new}}
        @poi_sets = LandmarkSet.search(params[:term]).limit(10).map {|g| {label: g.to_s, value: GeoIngredient.new}}

        json_response = @counties + @zipcodes + @cities + @custom_geographies + @pois + @poi_sets
        render json: json_response
      end
    end
  end

  private

  def od_zone_params
    params.require(:od_zone).permit(:name,
                                    :description,
                                    :agency_id,
                                    :agency,
                                    :zone_recipe,
                                    region_attributes: [:recipe])
  end

  def get_od_zones_for_current_user
    OdZone.for_user(current_user)
  end
end
