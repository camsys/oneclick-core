
# Module for helping Controllers respond to pages with multiple 
# remote form partials, serving them back individually
module RemoteFormResponder

  # before action, set the partial path if sent via the params
  def self.included(base)
    attr_accessor :partial_path
    base.before_action :set_partial_path
  end
  
  # Sets the partial_path instance variable from params
  def set_partial_path
    @partial_path = params[:partial_path]
  end
  
  # Renders a partial based on the partial path that has been set
  def respond_with_partial(layout_path: "/layouts/_panel")
    respond_to do |format|
      format.html do
        render template: partial_path, layout: layout_path
      end
    end
  end
  
  # Renders a partial if partial path has been set; otherwise, yield to the passed block
  def respond_with_partial_or(partial_layout: "/layouts/_panel", &block)  
    if partial_path.to_s.strip.present?
      respond_with_partial(layout_path: partial_layout)
    else
      yield
    end
  end
  
end
