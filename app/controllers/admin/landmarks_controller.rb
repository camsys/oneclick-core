class Admin::LandmarksController < Admin::AdminController
  load_and_authorize_resource

  def index
    @landmarks = Landmark.all.order(:name)
    # don't allow duplicate landmarks
    @landmarks = @landmarks.uniq { |landmark| landmark.name, landmark.agency_id }
    @landmark = Landmark.new
  end

  def update_all
    info_msgs = []
    error_msgs = []

    landmark_file = params[:landmarks][:file] if params[:landmarks]
    if !landmark_file.nil?
      response, message =  Landmark.update landmark_file
      if response
        info_msgs << message
      else
        error_msgs << message
      end
    else
      error_msgs << "Upload a csv file containing the new landmarks."
    end

    if error_msgs.size > 0
      flash[:danger] = error_msgs.to_sentence
    elsif info_msgs.size > 0
      flash[:success] = info_msgs.to_sentence
    end

    respond_to do |format|
      format.js
      format.html {redirect_to admin_landmarks_path}
    end
  end

  def update
    update_params = landmark_params
    @landmark.update_attributes(update_params)

    if @landmark.errors.empty?
      flash[:success] = "#{@landmark.name} Updated"
    else
      present_error_messages(@landmark)
    end

    respond_to do |format|
      format.js
      format.html {redirect_to admin_landmarks_path}
    end
  end

  def edit
  end

  def destroy
    @landmark.destroy
    flash[:success] = "#{@landmark.name} Deleted"
    redirect_to admin_landmarks_path
  end

  def create
    @landmark.update_attributes(landmark_params)

    @landmarks = Landmark.all.order(:name)

    if @landmark.save
      flash[:success] = "Created #{@landmark.name}"
      respond_to do |format|
        format.js
        format.html {redirect_to admin_landmarks_path}
      end
    else
      present_error_messages(@landmark)
      respond_to do |format|
        format.html {render :index}
      end
    end
  end

  private

  def landmark_params
  	params.require(:landmark).permit(:name, :street_number, :route, :city, :state, :zip, :lat, :lng)
  end

end
