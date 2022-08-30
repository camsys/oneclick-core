class Admin::OdZonesController < Admin::AdminController
  before_action :load_agency_from_params_or_user, only: [:new]

  include GeoKitchen

  def index
    @od_zones = get_od_zones_for_current_user
  end

  def show
    @od_zone = OdZone.find(params[:id])
    @agency =  current_user.current_agency || Agency.first
    @od_zone.build_geographies # Build empty region.
  end

  def new
    @od_zone = OdZone.new
    @od_zone.agency = @agency
    @od_zone.build_geographies # Build empty region.
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

    if @od_zone.valid? && @od_zone.update_attributes(od_zone_params)
      flash[:success] = "O/D Zone successfully updated."
      redirect_to admin_od_zones_path
    else
      flash[:danger] = "There was an issue updating the O/D Zone."
      redirect_to edit_admin_od_zone_path(id: @od_zone.id)
    end
  end

  def destroy
    od_zone = OdZone.find(params[:id])
    if od_zone.destroy
      flash[:success] = "O/D Zone successfully deleted."
    else
      flash[:danger] = od_zone.errors.full_messages.join(" ")
    end
    redirect_to admin_od_zones_path
  end

  # Serves JSON responses to geography searches to enable autocomplete
  def autocomplete
    respond_to do |format|
      format.json do
        @counties = County.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h, geom: g.geom_to_array}}
        @zipcodes = Zipcode.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h, geom: g.geom_to_array}}
        @cities = City.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h, geom: g.geom_to_array}}
        @custom_geographies = CustomGeography.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s, value: g.to_geo.to_h, geom: g.geom_to_array}}
        @pois = Landmark.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s.gsub('Landmark','POI'), value: g.to_geo.to_h, geom: g.geom_buffer_to_array}}
        @poi_sets = LandmarkSet.search(params[:term]).limit(10).map {|g| {label: g.to_geo.to_s.gsub('LandmarkSet','Set of POIs'), value: g.to_geo.to_h, geom: g.geom_to_array}}

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
    region_attributes: [:recipe, :id]
    )
  end

  def get_od_zones_for_current_user
    #OdZone.for_user(current_user)
    OdZone.accessible_by(current_ability)
                                    .joins(:agency)
                                    .merge(Agency.order(:name))
                                    .includes(:agency)
  end
end
