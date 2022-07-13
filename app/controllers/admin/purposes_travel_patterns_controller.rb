class Admin::PurposesTravelPatternsController < Admin::AdminController
  before_action :load_agency_from_params_or_user, only: [:new]

  def index
    @purposes = Purpose.accessible_by(current_ability)
                       .joins(:agency)
                       .merge(Agency.order(:name))
                       .includes(:agency)
    authorize! :read, @purposes
  end

  def show
    @purpose = Purpose.find(params[:id])
    authorize! :read, @purpose
  end

  def destroy
    @purpose = Purpose.find(params[:id])
    authorize! :destroy, @purpose
    @purpose.destroy

    redirect_to admin_trip_purposes_path
  end

  def new
    @purpose = Purpose.new(agency: @agency)
    authorize! :create, @purpose
  end

  def create
    @purpose = Purpose.new(purpose_params)
    @purpose.agency_id = params[:agency_id]
    authorize! :create, @purpose
  	@purpose.save

  	redirect_to admin_trip_purposes_path
  end

  def edit
    @purpose = Purpose.includes(:agency).find(params[:id])
    authorize! :edit, @purpose
  end

  def update
    @purpose = Purpose.find(params[:id])
    authorize! :edit, @purpose
    @purpose.update(purpose_params)
    redirect_to admin_trip_purposes_path
  end

  private

  def purpose_params
  	params.require(:purpose).permit(:name, :description)
  end

end
