class Admin::AccommodationsController < Admin::AdminController
  load_and_authorize_resource

  def index
    @accommodations = @accommodations.order(:code)
    @new_accommodation = Accommodation.new 
  end

  def destroy
    @accommodation.destroy
    redirect_to admin_accommodations_path
  end

  def create
  	@accommodation.update_attributes(accommodation_params)
  	redirect_to admin_accommodations_path
  end

  def edit
  end

  def update
    @accommodation.update_attributes(accommodation_params)
    translations = params[:accommodation]
    translations.each do |translation, value|
      @accommodation.set_translation(translation.split('_').first, translation.split('_').last, value)
    end
    flash[:success] = "Translations Updated"
    redirect_to edit_admin_accommodation_path(@accommodation)
  end

  private

  def accommodation_params
  	params.require(:accommodation).permit(:code, :rank)
  end

end
