class Admin::ConfigsController < Admin::AdminController
  authorize_resource

  def index
    @open_trip_planner = Config.where(key: 'open_trip_planner').first_or_initialize
    @tff_api_key = Config.where(key: 'tff_api_key').first_or_initialize
    @uber_token = Config.where(key: 'uber_token').first_or_initialize
    @daily_scheduled_tasks = Config.where(key: 'daily_scheduled_tasks').first_or_initialize
  end

  def set_open_trip_planner
    set_config config_params[:value], 'open_trip_planner'
  end

  def set_tff_api_key
    set_config config_params[:value], 'tff_api_key'  
  end

  def set_uber_token
    set_config config_params[:value], 'uber_token'
  end
  
  def set_daily_scheduled_tasks
    daily_scheduled_tasks = config_params(true)[:value].select(&:present?).map(&:to_sym)
    set_config daily_scheduled_tasks, 'daily_scheduled_tasks'
  end

  def set_config value, key
    @config = Config.where(key: key).first_or_initialize
    
    @config.value = value
    if @config.save
      flash[:success] = "#{key} successfully updated"
    else
      present_error_messages(@config)
    end

    respond_to do |format|
      format.js
      format.html {redirect_to admin_configs_path}
    end
  end
  
  def config_params(value_serialized=false)
    if value_serialized
      params.require(:config).permit(value: [])
    else
      params.require(:config).permit(:value)
    end
  end

end
