class Admin::AccommodationsController < Admin::AdminController
  load_and_authorize_resource

  def index
    # @accommodations = Accommodation.all.order(:code)
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

  def edit
    @accommodation = Accommodation.find(params[:id])
  end

  def update
    @accommodation = Accommodation.find(params[:id])
    translations = params[:accommodation]
    translations.each do |translation, value|
      @accommodation.set_translation(translation.split('_').first, translation.split('_').last, value)
    end
    flash[:success] = "Translations Updated"
    redirect_to edit_admin_accommodation_path(@accommodation)
  end

  private

  def accommodation_params
  	params.require(:accommodation).permit(:code)
  end

end
