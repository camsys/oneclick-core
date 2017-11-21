# Service object for Logging requests made to API Controllers
class ApiRequestLogger
  
  attr_reader :include_controllers, :exclude_controllers, :exclude_actions
  
  # Accepts an options hash to configure which actions to log.
  # *** OPTIONS: ***
  # => include_controllers: Pass an array of strings which are either controller
  # class names or substrings of those names. Will only log requests to controllers
  # that match one of the names on the list. Defaults to 'Api::'.
  # => exclude_controllers: Pass an array of controller name strings/substrings.
  # Will not log requests to any of those controllers.
  # => exclude_actions: Pass a hash with keys that are controller names, and 
  # values that are arrays of action names to be excluded for that controller.
  def initialize(opts={})
    
    # By default, only log requests for Api-namespaced controllers.
    # Do not exclude any controllers or controller actions.
    @include_controllers = opts[:include_controllers] || ["Api::"]
    @exclude_controllers = opts[:exclude_controllers] || []
    @exclude_actions = Hash.new([]).merge(opts[:exclude_actions] || {})
  end
  
  # Start logging requests
  def start
    
    # Subscribes to an event that occurs whenever a controller request is made
    ActiveSupport::Notifications.subscribe 'process_action.action_controller' do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      payload = event.payload
      
      # The controller and action are included and not excluded, create a 
      # RequestLog object for the request.
      if log?(payload[:controller], payload[:action])
        RequestLog.create({
          controller: payload[:controller],
          action: payload[:action],
          params: payload[:params],
          status_code: payload[:status],
          auth_email: payload[:headers]["X-User-Email"],
          duration: event.duration.to_i
        })
      end
      
    end
  end

  # Stop logging requests
  def stop
    ActiveSupport::Notifications.unsubscribe 'process_action.action_controller'
  end
  
  # Pass it a controller class name and action name, and returns boolean for 
  # whether or not that class and action should be logged
  def log?(controller_class_name, action_name)
    @include_controllers.any? { |ctrl| controller_class_name.include?(ctrl) } &&
    @exclude_controllers.none? { |ctrl| controller_class_name.include?(ctrl) } &&
    @exclude_actions[controller_class_name].exclude?(action_name)
  end
  
end
