class ConfigsController < ApplicationController

  def index
    @landmarks = Landmark.count 
    @open_trip_planner = Config.where(key: 'open_trip_planner').first_or_initialize
  end

  def set_landmarks

    info_msgs = []
    error_msgs = []

    boundary_file = params[:setting][:file] if params[:setting]
    if !boundary_file.nil?
      gs = GeographyService.new
      info_msgs << gs.store_callnride_boundary(boundary_file.tempfile.path)
    else
      error_msgs << "Upload a zip file containing a shape file."
    end


    if error_msgs.size > 0
      flash[:error] = error_msgs.join(' ')
    elsif info_msgs.size > 0
      flash[:success] = info_msgs.join(' ')
    end


    respond_to do |format|
      format.js
      format.html {redirect_to configs_path}
    end

  end

  def set_open_trip_planner

    info_msgs = []
    error_msgs = []

    otp = params[:config][:value] if params[:config]

    if !otp.blank?
      setting = Config.where(key: 'open_trip_planner').first_or_initialize
      setting.value = otp
      setting.save
    else
      error_msgs << "OpenTripPlanner URL cannot be blank."
    end


    if error_msgs.size > 0
      flash[:error] = error_msgs.join(' ')
    elsif info_msgs.size > 0
      flash[:success] = info_msgs.join(' ')
    end


    respond_to do |format|
      format.js
      format.html {redirect_to configs_path}
    end
  end

end