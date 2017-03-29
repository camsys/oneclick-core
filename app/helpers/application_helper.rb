module ApplicationHelper

  # Allows named yields within partial layouts
  def yield_content(content_key)
    view_flow.content.delete(content_key)
  end

  # Construct a name for an input control appropriate for setting nested attributes
  def input_name form_builder, nest, attribute=nil, count=nil
    name = form_builder.object_name + '[' + nest.to_s + '_attributes]['
    name += count.to_s if !count.nil?
    name += '][' + attribute.to_s + ']' if !attribute.nil?
    name
  end

end
