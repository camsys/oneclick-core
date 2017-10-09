class Admin::ConfigsController < Admin::AdminController
  include RemoteFormResponder
  
  authorize_resource
  before_action :load_configs, only: [:index, :update]
  
  PERMITTED_CONFIGS = [
    :open_trip_planner,
    :tff_api_key,
    :uber_token,
    :ride_pilot_url,
    :ride_pilot_token,
    :feedback_overdue_days,
    daily_scheduled_tasks: []
  ].freeze

  def index
  end
  
  def update
    configs = configs_params.to_h.map do |k,v|
      [ @configs.find_or_create_by(key: k).id, { value: format_config_value(k, v) } ]
    end.to_h
        
    # Update all relevant configs at once, as a batch
    @errors = Config.update(configs.keys, configs.values)
                    .map(&:errors)
                    .select(&:present?)
    flash[:danger] = @errors.flat_map(&:full_messages)
                            .to_sentence unless @errors.empty?
    respond_with_partial    
  end

  # def set_open_trip_planner
  #   set_config config_params[:value], 'open_trip_planner'
  # end
  # 
  # def set_tff_api_key
  #   set_config config_params[:value], 'tff_api_key'  
  # end
  # 
  # def set_uber_token
  #   set_config config_params[:value], 'uber_token'
  # end
  # 
  # def set_daily_scheduled_tasks
  #   daily_scheduled_tasks = config_params(true)[:value].select(&:present?).map(&:to_sym)
  #   set_config daily_scheduled_tasks, 'daily_scheduled_tasks'
  # end
  # 
  # def set_config value, key
  #   @config = Config.where(key: key).first_or_initialize
  #   
  #   @config.value = value
  #   if @config.save
  #     flash[:success] = "#{key} successfully updated"
  #   else
  #     present_error_messages(@config)
  #   end
  # 
  #   respond_to do |format|
  #     format.js
  #     format.html {redirect_to admin_configs_path}
  #   end
  # end
  # 
  # def config_params(value_serialized=false)
  #   if value_serialized
  #     params.require(:config).permit(value: [])
  #   else
  #     params.require(:config).permit(:value)
  #   end
  # end
  
  def configs_params
    params.require(:config).permit(PERMITTED_CONFIGS)
  end
  
  def load_configs
    @configs = Config.where(key: PERMITTED_CONFIGS.flat_map {|k| k.try(:keys) || k })
  end
  
  # This helper method allows pre-formatting of values before updating the
  # config itself. This is useful if a particular config requires a special 
  # format, for example the daily_scheduled_tasks must be an array of symbols.
  def format_config_value(key, value)
    case key.to_sym
    when :daily_scheduled_tasks
      return value.select(&:present?).map(&:to_sym)
    when :feedback_overdue_days
      return value.to_i
    else
      return value
    end
  end

end
