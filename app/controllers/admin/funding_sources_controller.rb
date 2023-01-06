class Admin::FundingSourcesController < Admin::AdminController
  load_and_authorize_resource
  before_action :load_agency_from_params_or_user, only: [:new]

  def index
    @funding_sources = FundingSource.for_user(current_user)
                                    .accessible_by(current_ability)
                                    .joins(:agency)
                                    .merge(Agency.order(:name))
                                    .includes(:agency)
    #authorize! :read, @funding_sources
  end

  
  def show
  end

  def new
    @funding_source = FundingSource.new(agency: @agency)
    #authorize! :create, @funding_source
    #@funding_source.agency = @agency
  end

  def edit
  end

  def create
    if @funding_source.save
      redirect_to admin_funding_sources_path, notice: 'Funding Source was successfully created.'
    else
      flash.now[:danger] = 'Funding Source could not be created.'
      render :new
    end
  end

  def update
    if @funding_source.update(funding_source_params)
      redirect_to admin_funding_sources_path, notice: 'Funding Source was successfully updated.'
    else
      flash.now[:danger] = 'Funding Source could not be updated.'
      render :edit
    end
  end

  def destroy
    if @funding_source.destroy
      flash[:success] = "Funding Source successfully deleted."
    else
      flash[:danger] = @funding_source.errors.full_messages.join(" ")
    end
    redirect_to admin_funding_sources_path
  end

  private
  
  def funding_source_params
    params.require(:funding_source).permit(:name, :description, :agency_id)
  end
end
