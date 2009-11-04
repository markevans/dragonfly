Given /^a stored image "(.+?)" with dimensions (\d+)x(\d+)$/ do |name, width, height|
  tempfile = Tempfile.new(name)
  `convert -resize #{width}x#{height}! #{SAMPLE_IMAGE_PATH} #{tempfile.path}`
  temp_object = APP.temp_object_class.new(tempfile)
  uid = APP.datastore.store(temp_object)
  TEMP_IMAGES[name] = uid
end

When /^I go to the url for image "(.+?)", with format '([^']+?)'$/ do |name, ext|
  make_image_request name, :mime_type => Dragonfly::MimeTypes.mime_type_for(ext)
end

When /^I go to the url for image "(.+?)", with format '(.+?)' and resize geometry '(.+?)'$/ do |name, ext, geometry|
  make_image_request(name,
    :mime_type => Dragonfly::MimeTypes.mime_type_for(ext),
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
  @response.body.should have_width(width.to_i)
end

Then "the image should have height '(.+?)'" do |height|
  @response.body.should have_height(height.to_i)
end

Then "the image should have format '(.+?)'" do |format|
  @response.body.should have_format(format)
end
