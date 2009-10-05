Given /^a stored image "(.+?)" with dimensions (\d+)x(\d+)$/ do |name, width, height|
  tempfile = Tempfile.new(name)
  `convert -resize #{width}x#{height}! #{SAMPLE_IMAGE_PATH} #{tempfile.path}`
  temp_object = APP.temp_object_class.new(tempfile)
  uid = APP.datastore.store(temp_object)
  TEMP_IMAGES[name] = uid
end

When /^I go to the url for image "(.+?)", with format '([^']+?)'$/ do |name, ext|
  make_image_request name, :mime_type => mime_type_from_extension(ext)
end

When /^I go to the url for image "(.+?)", with format '(.+?)' and resize geometry '(.+?)'$/ do |name, ext, geometry|
  make_image_request(name,
    :mime_type => mime_type_from_extension(ext),
    :processing_method => :resize,
    :processing_options => {:geometry => geometry}
  )
end

Then "the response should be OK" do
  @response.status.should == 200
end

Then "the response should have mime-type '(.+?)'" do |mime_type|
  @response.headers['Content-Type'].should == mime_type
end

Then "the image should have width '(.+?)'" do |width|
  image_properties(@response.body)[:width].should == width
end

Then "the image should have height '(.+?)'" do |height|
  image_properties(@response.body)[:height].should == height
end

Then "the image should have format '(.+?)'" do |format|
  image_properties(@response.body)[:format].should == format
end
