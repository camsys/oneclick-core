class ConfigsController < ApplicationController

  def index
    @open_trip_planner = Config.where(key: 'open_trip_planner').first_or_initialize
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