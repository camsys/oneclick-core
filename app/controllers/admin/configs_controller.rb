class Admin::ConfigsController < Admin::AdminController
  authorize_resource

  def index
    @open_trip_planner = Config.where(key: 'open_trip_planner').first_or_initialize
    @tff_api_key = Config.where(key: 'tff_api_key').first_or_initialize
    @uber_token = Config.where(key: 'uber_token').first_or_initialize
  end

  def set_open_trip_planner
    set_config params, 'open_trip_planner'
  end

  def set_tff_api_key
    set_config params, 'tff_api_key'  
  end

  def set_uber_token
    set_config params, 'uber_token'
  end

  def set_config params, key
    info_msgs = []
    error_msgs = []

    value = params[:config][:value] if params[:config]

    if !value.blank?
      setting = Config.where(key: key).first_or_initialize
      setting.value = value
      setting.save
    else
      error_msgs << "#{key} cannot be blank."
    end

    if error_msgs.size > 0
      flash[:danger] = error_msgs.join(' ')
    elsif info_msgs.size > 0
      flash[:success] = info_msgs.join(' ')
    end

    respond_to do |format|
      format.js
      format.html {redirect_to admin_configs_path}
    end
  end

end
