module ApplicationHelper


  ### FORM INPUT NAME HELPERS ###
  # Help build custom forms that communicate properly with controllers
  
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
  
  ### form input name helpers ###
  


  ### REMOTE PARTIAL HELPERS ###
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

  # This sends the partial's path to the controller on form submit, 
  # so it can serve back the correct partial. Also, refreshes the flash
  # messages.
  def remote_form_input
    html =  "<input class='hidden' name='partial_path' type'text' value='#{partial_path}'>"
    html << "<script>"
    html <<   "$(document).ready(function() {
                $('#flash-display').replaceWith('#{escape_javascript render partial: "shared/flash"}');
              });"
    html << "</script>"
    html.html_safe
  end
  
  ### remote partial helpers ###
  
  
  
  ### TEMPLATES & WIDGETS ###
  # These methods render small bits of HTML based on parameters.
  
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
  
  # Renders a Logo Upload Form Element. Pass in a reference to the form builder object,
  # and an options hash
  def logo_upload_input(f, options={})
    img_src = options[:img_src] || f.object.logo.thumb.url
    field_name = options[:field_name] || :logo
    readonly = options[:readonly]
    
    html =  "<div class='form-group file optional'>"
    html <<   "<div class='col-sm-1'>"
    html <<     "<img src='#{img_src}'>"
    html <<   "</div>"
    html <<   f.label(field_name, class: "control-label col-sm-2")
    html <<   "<div class='col-sm-9'>"
    html <<     "<div class='input-group col-xs-12'>"
    html <<     f.input_field(field_name, class: "form-control file optional", type: "file", readonly: readonly)
    html <<     "</div>"
    html <<   "</div>"
    html << "</div>"
    
    html.html_safe
  end

  # Renders a centered back link to the desired URL
  def back_link(path, opts={})
    link_label = opts[:label] || "Back"
    
    html = "<div class='text-center'>"
    html << link_to(link_label, path, method: :get, class: 'btn btn-lg btn-link')
    html << "</div>"
    
    html.html_safe
  end

  ### templates & widgets ###
  
  
  
  ### MISCELLANEOUS HELPERS ###
  
  # Allows named yields within partial layouts
  def yield_content(content_key)
    view_flow.content.delete(content_key)
  end
  
  # Converts alert type to appropriate bootstrap class
  def map_alert(type)
    alert_mappings = {
      notice: "success",
      alert: "warning"
    }
    alert_mappings[type.to_sym] || type.to_s
  end

  def in_travel_patterns_mode?
    Config.dashboard_mode.to_sym == :travel_patterns
  end
  ### miscellaneous helpers ###

end
