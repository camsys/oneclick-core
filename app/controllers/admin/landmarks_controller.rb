class Admin::LandmarksController < Admin::AdminController
  authorize_resource

  def index
    @landmarks = Landmark.all.order(:name)
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

end
