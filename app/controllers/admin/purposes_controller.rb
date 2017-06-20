class Admin::PurposesController < Admin::AdminController

  def index
    @purposes = Purpose.all.order(:code)
    @new_purpose= Purpose.new 
  end

  def destroy
    @purpose = Purpose.find(params[:id])
    @purpose.destroy
    redirect_to admin_purposes_path
  end

  def create
  	Purpose.create!(purpose_params)
  	redirect_to admin_purposes_path
  end

  def edit
    @purpose = Purpose.find(params[:id])
  end

  def update
    @purpose = Purpose.find(params[:id])
    translations = params[:purpose]
    translations.each do |translation, value|
      @purpose.set_translation(translation.split('_').first, translation.split('_').last, value)
    end
    flash[:success] = "Translations Updated"
    redirect_to edit_admin_purpose_path(@purpose)
  end

  private

  def purpose_params
  	params.require(:purpose).permit(:code)
  end

end