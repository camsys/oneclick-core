
class Net::HTTPResponse

  # Custom success? method returns a boolean of whether the response was successful
  def success?
    self.kind_of? Net::HTTPSuccess
  end

  # Custom failure? method returns a boolean of whether the response was a client or server error.
  def failure?
    self.kind_of?(Net::HTTPClientError) || self.kind_of?(Net::HTTPServerError)
  end

end
