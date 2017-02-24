module ApplicationHelper

  # Allows named yields within partial layouts
  def yield_content(content_key)
    view_flow.content.delete(content_key)
  end
end
