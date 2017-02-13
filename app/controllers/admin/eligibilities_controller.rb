class Admin::EligibilitiesController < Admin::AdminController

  def index
    @eligibilities = Eligibility.all.order(:code)
  end

  def destroy
    @eligibility = Eligibility.find(params[:id])
    @eligibility.destroy
    redirect_to admin_eligibilities_path
  end

end