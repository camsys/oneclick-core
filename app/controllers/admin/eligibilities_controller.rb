class Admin::EligibilitiesController < Admin::AdminController
  load_and_authorize_resource

  def index
    @eligibilities = @eligibilities.order(:code)
    @new_eligibility = Eligibility.new 
  end

  def destroy
    @eligibility.destroy
    redirect_to admin_eligibilities_path
  end

  def create
  	@eligibility.update_attributes(eligibility_params)
  	redirect_to admin_eligibilities_path
  end

  def edit
  end

  def update
    translations = params[:eligibility]
    translations.each do |translation, value|
      @eligibility.set_translation(translation.split('_').first, translation.split('_').last, value)
    end
    flash[:success] = "Translations Updated"
    redirect_to edit_admin_eligibility_path(@eligibility)
  end

  private

  def eligibility_params
  	params.require(:eligibility).permit(:code)
  end

end
