class Admin::EligibilitiesController < Admin::AdminController

  def index
    @eligibilities = Eligibility.all.order(:code)
    @new_eligibility = Eligibility.new 
  end

  def destroy
    @eligibility = Eligibility.find(params[:id])
    @eligibility.destroy
    redirect_to admin_eligibilities_path
  end

  def create
  	Eligibility.create!(eligibility_params)
  	redirect_to admin_eligibilities_path
  end

  def edit
    @eligibility = Eligibility.find(params[:id])
  end

  def update
    @eligibility = Eligibility.find(params[:id])
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