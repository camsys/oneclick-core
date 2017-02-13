class Admin::AccommodationsController < Admin::AdminController

  def index
    @accommodations = Accommodation.all.order(:code)
    @new_accommodation = Accommodation.new 
  end

  def destroy
    @accommodation = Accommodation.find(params[:id])
    @accommodation.destroy
    redirect_to admin_accommodations_path
  end

  def create
  	Accommodation.create!(accommodation_params)
  	redirect_to admin_accommodations_path
  end

  private

  def accommodation_params
  	params.require(:accommodation).permit(:code)
  end

end