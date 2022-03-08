class Admin::LandmarkSetsController < Admin::AdminController
  load_and_authorize_resource
  def index
  end

  def create
    create_params = landmark_set_params
    id = create_params[:agency_id]
    agency = Agency.find id
    # NOTE: the below probably could be cleaned up a bit better or turned into a custom validator for agency
    if agency.nil?
      flash[:error] = 'agency cannot be blank'
      return redirect_to admin_landmark_sets_path
    end
    LandmarkSet.create(create_params)
    redirect_to admin_landmark_sets_path
  end

  private
  def landmark_set_params
    params.require(:landmark_set).permit([
      :name,
      :description,
      :agency_id
     ])
  end

end
