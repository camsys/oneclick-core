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

  # Constructs an form input name based on a model and an arbitrary list of nested attributes
  def input_name_for(object, *attributes)
    object.class.name.underscore + attributes.map{|att| "[#{att.to_s}]"}.join
  end

  ###
  # Helpers for handling naming and rendering of remote form partials
  def partial_path
    self.instance_variable_get(:@virtual_path)
  end

  def form_id_from_path
    "form" + partial_path.split('/').last.dasherize
  end

  def form_selector_from_id
    "form#" + form_id_from_path
  end

  # This sends the partial's path to the controller on form submit, so it can serve back the correct partial
  def remote_form_input
    "<input class='hidden' name='partial_path' type'text' value='#{partial_path}'>".html_safe
  end

end
