class Admin::TravelPatternsController < Admin::AdminController
  def index
    @travel_patterns = get_travel_patterns_for_current_user
  end

  def show
    @travel_pattern = TravelPattern.find(params[:id])
    @agency = @travel_pattern.agency
  end

  def new
    @travel_pattern = TravelPattern.new
    @agency = current_user.current_agency
  end

  def create

  end

  def edit
    @travel_pattern = TravelPattern.find(params[:id])
    @agency = @travel_pattern.agency
  end

  def update

  end

  def destroy
    travel_pattern = TravelPattern.find(params[:id])
    if travel_pattern.destroy
      redirect_to admin_travel_patterns_path
    end
  end

  private

  def get_travel_patterns_for_current_user
    TravelPattern.for_user(current_user)
  end
end
