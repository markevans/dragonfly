module ImageHelpers
  
  def make_image_request(name, parameters = {})
    request = Rack::MockRequest.new(APP)
    url = APP.url_handler.url_for(TEMP_IMAGES[name], parameters)
    @response = request.get(url)
  end
  
end