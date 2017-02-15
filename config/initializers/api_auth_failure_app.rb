class ApiAuthFailure < Devise::FailureApp

  # If we need to add additional functionality to or change the response
  # format of JSON request failures, we can do so by overwriting method(s) from devise/failure_app.rb
  def http_auth_body
    return i18n_message unless request_format
    method = request_format == "*/*" ? "to_json" : "to_#{request_format}"
    if method == "to_xml"
      { error: i18n_message }.to_xml(root: "errors")
    elsif {}.respond_to?(method)
      { error: i18n_message }.send(method)
    else
      i18n_message
    end
  end

end
