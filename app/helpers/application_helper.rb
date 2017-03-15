module ApplicationHelper

  # Allows named yields within partial layouts
  def yield_content(content_key)
    view_flow.content.delete(content_key)
  end

  # Returns an html string of the given partial
  def partial_to_string(*args, &block)
    ApplicationController.new.render_to_string(*args, &block)
  end

end
