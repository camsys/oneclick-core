class LandmarksController < AdminController

  def index
    @landmarks = Landmark.all.order(:name)
  end

  def update_all
    info_msgs = []
    error_msgs = []

    landmark_file = params[:landmarks][:file] if params[:landmarks]
    if !landmark_file.nil?
      reponse, message =  Landmark.update landmark_file
      if response
        info_msgs << message
      else
        error_msgs << message
      end
    else
      error_msgs << "Upload a csv file containing the new landmarks."
    end

    if error_msgs.size > 0
      flash[:error] = error_msgs.join(' ')
    elsif info_msgs.size > 0
      flash[:success] = info_msgs.join(' ')
    end

    respond_to do |format|
      format.js
      format.html {redirect_to landmarks_path}
    end
  end

end