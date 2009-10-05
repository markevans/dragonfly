module ImageHelpers
  
  def make_image_request(name, parameters = {})
    request = Rack::MockRequest.new(APP)
    url = APP.url_handler.url_for(TEMP_IMAGES[name], parameters)
    @response = request.get(url)
  end
  
  def image_properties(data)
    tempfile = Tempfile.new('image')
    tempfile.write(@response.body)
    tempfile.close
    details = `identify #{tempfile.path}`
    # example of details string:
    # myimage.png PNG 200x100 200x100+0+0 8-bit DirectClass 31.2kb
    filename, format, geometry, geometry_2, depth, image_class, size = details.split(' ')
    width, height = geometry.split('x')
    {
      :filename => filename,
      :format => format.downcase,
      :width => width,
      :height => height,
      :depth => depth,
      :image_class => image_class,
      :size => size
    }
  end
  
end