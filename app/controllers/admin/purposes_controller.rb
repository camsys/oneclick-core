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

  private

  def purpose_params
  	params.require(:purpose).permit(:code)
  end

end