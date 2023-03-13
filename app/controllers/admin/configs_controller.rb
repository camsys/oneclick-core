# TO ADD A NEW CONFIG:
#   1. Add its key (as a symbol) to this PERMITTED_CONFIGS array below.
#   2. If the config's value is NOT a string, add a when statement to the 
#      format_config_value method to preformat the incoming value, converting
#      it to the proper data format (e.g. value.to_f )

class Admin::ConfigsController < Admin::AdminController
  include RemoteFormResponder
  include ConfigHelpers

  authorize_resource
  before_action :load_configs, only: [:index, :update]
  helper_method :build_dashboard_mode_collection

  PERMITTED_CONFIGS = [
    :open_trip_planner,
    :open_trip_planner_version,
    :tff_api_key,
    :uber_token,
    :lyft_client_token,
    :ride_pilot_url,
    :ride_pilot_token,
    :ecolane_url,
    :trapeze_url,
    :trapeze_user,
    :trapeze_ada_funding_sources,
    :trapeze_ignore_polygon_id,
    :trapeze_check_polygon_id,
    :trapeze_token,
    :feedback_overdue_days,
    :ui_url,
    :require_user_confirmation,
    :max_walk_minutes,
    :walk_reluctance,
    :bike_reluctance,
    :dashboard_mode,
    :maximum_booking_notice,
    daily_scheduled_tasks: []
  ].freeze

  def index
    @dashboard_mode_collection = build_dashboard_mode_collection
  end
  
  def update
    configs = configs_params.to_h.map do |k,v|
      [ @configs.find_or_create_by(key: k).id, { value: format_config_value(k, v) } ]
    end.to_h
        
    # Update all relevant configs at once, as a batch 
    @errors = Config.update(configs.keys, configs.values)
                    .map(&:errors)
                    .select(&:present?)
    if @errors.empty?
      flash[:success] = 'Config updated sucessfully'
    else
      flash[:danger] = @errors.flat_map(&:full_messages)
                              .to_sentence unless @errors.empty?
    end
    respond_with_partial
  end
  
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
    when :feedback_overdue_days, :max_walk_minutes, :walk_reluctance, :bike_reluctance, :maximum_booking_notice
      return value.to_i
    when :require_user_confirmation
      return (value == "true")
    when :trapeze_ada_funding_sources
      return value.delete(' ').split(',')
    else
      return value
    end
  end

  private

  def build_dashboard_mode_collection
    PERMITTED_DASHBOARD_MODES.map do |mode|
      DashboardModeInputHelper.new(mode)
    end
  end
end
