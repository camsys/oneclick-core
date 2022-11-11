class Admin::PurposesController < Admin::AdminController
  load_and_authorize_resource

  def index
    @purposes = @purposes.order(:code)
    @new_purpose= Purpose.new 
  end

  def destroy
    if @purpose.destroy
      flash[:success] = "Purpose successfully deleted."
    else
      flash[:danger] = @purpose.errors.full_messages.join(" ")
    end
    redirect_to admin_purposes_path
  end

  def create
  	purpose = Purpose.new(purpose_params)
    purpose[:name] = purpose.code if purpose.name.blank?
    purpose.save!
  	redirect_to admin_purposes_path
  end

  def edit
  end

  def update
    translations = params[:purpose]
    translations.each do |translation, value|
      @purpose.set_translation(translation.split('_').first, translation.split('_').last, value)
    end
    flash[:success] = "Translations Updated"
    redirect_to edit_admin_purpose_path(@purpose)
  end

  private

  def purpose_params
  	params.require(:purpose).permit(:code, :name)
  end

end
