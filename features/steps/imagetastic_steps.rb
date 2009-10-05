Given /^a stored image "(.+?)" with dimensions (\d+)x(\d+)$/ do |name, width, height|
  tempfile = Tempfile.new(name)
  `convert -resize #{width}x#{height}! #{SAMPLE_IMAGE_PATH} #{tempfile.path}`
  temp_object = APP.temp_object_class.new(tempfile)
  uid = APP.datastore.store(temp_object)
  TEMP_IMAGES[name] = uid
end

def make_image_request(name, parameters = {})
  request = Rack::MockRequest.new(APP)
  url = APP.url_handler.url_for(TEMP_IMAGES[name], parameters)
  @response = request.get(url)
end

When /^I go to the url for image "(.+)", with format '(.+)'$/ do |name, ext|
  make_image_request name, :mime_type => mime_type_from_extension(ext)
end

Then "the response should be OK" do
  @response.status.should == 200
end

Then "the response should have mime-type '(.+)'" do |mime_type|
  @response.headers['Content-Type'].should == mime_type
end

Then "the image should have width '(.+)'" do |width|
  tempfile = Tempfile.new('image')
  tempfile.write(@response.body)
  raise `identify #{tempfile.path}`
end 