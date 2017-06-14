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
  
  # Renders a bootstrap form group with static text
  def static_form_group(options={})
    ("<div class='form-group'>" +
      "<label class='col-sm-3 control-label'>" +
        (options[:label_html] || options[:label].to_s) +
      "</label>" +
      "<div class='col-sm-9'>" +
        ( 
          options[:value_html] ||
          "<p class='form-control-static'>" + options[:value].to_s + "</p>"
        ) +
      "</div>" +
    "</div>").html_safe
  end
  
  # Renders a pretty 0-5 star rating bar
  def rating_stars(n, opts={})
    out_of = opts[:out_of] || 5
    wrapper_class = opts[:wrapper_class] || ""
    
    html = "<div class='rating-stars #{wrapper_class}'>"
    n.times { html << "<span class='glyphicon glyphicon-star'></span>" }
    (out_of - n).times { html << "<span class='glyphicon glyphicon-star-empty text-muted'></span>" }
    html << "</div>"
    
    html.html_safe
  end

end
