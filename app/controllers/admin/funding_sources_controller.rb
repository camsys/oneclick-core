class Admin::FundingSourcesController < Admin::AdminController
  load_and_authorize_resource except: :index

  def index
    @funding_sources = FundingSource.accessible_by(current_ability)
                                    .joins(:agency)
                                    .merge(Agency.order(:name))
                                    .includes(:agency)
    authorize! :read, @funding_sources
  end

  
  def show
  end

  def new
    @funding_source.agency = Agency.find(params[:agency_id])
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
    @funding_source.destroy
    redirect_to admin_funding_sources_path, notice: 'Funding Source was successfully destroyed.'
  end

  private
  
  def funding_source_params
    params.require(:funding_source).permit(:name, :description, :agency_id)
  end
end
