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

  private

  def eligibility_params
  	params.require(:eligibility).permit(:code)
  end

end