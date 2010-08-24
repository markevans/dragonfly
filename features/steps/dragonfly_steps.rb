require 'tempfile'

Given /^we are using the app for (\w+)$/ do |app_name|
  $app = Dragonfly[app_name.to_sym]
end

Given /^a stored file "(.+?)"$/ do |name|
  file = File.new(File.dirname(__FILE__) + "/../../samples/#{name}")
  uid = $app.store(file)
  TEMP_FILES[name] = uid
end

Given /^a stored image "(.+?)" with dimensions (\d+)x(\d+)$/ do |name, width, height|
  tempfile = Tempfile.new(name)
  `convert -resize #{width}x#{height}! #{SAMPLE_IMAGE_PATH} #{tempfile.path}`
  uid = $app.store(tempfile)
  TEMP_FILES[name] = uid
end

When /^I go to the url for "(.+?)"$/ do |name|
  uid = TEMP_FILES[name]
  make_request $app.fetch(uid)
end

When /^I go to the url for "(.+?)", with format '([^']+?)'$/ do |name, format|
  uid = TEMP_FILES[name]
  make_request $app.fetch(uid).encode(format)
end

When /^I go to the url for "(.+?)", with format '(.+?)' and resize geometry '(.+?)'$/ do |name, format, geometry|
  uid = TEMP_FILES[name]
  make_request $app.fetch(uid).process(:resize, geometry).encode(format)
end

When /^I go to the url for "(.+?)", with shortcut '([^']+?)'$/ do |name, geometry|
  uid = TEMP_FILES[name]
  make_request $app.fetch(uid).thumb(geometry)
end

Then "the response should be OK" do
  @response.status.should == 200
end

Then /the response should have mime-type '(.+?)'/ do |mime_type|
  @response.headers['Content-Type'].should == mime_type
end

Then /^the image should have width '(.+?)'$/ do |width|
  @response.body.should have_width(width.to_i)
end

Then /^the image should have height '(.+?)'$/ do |height|
  @response.body.should have_height(height.to_i)
end

Then /^the image should have format '(.+?)'$/ do |format|
  @response.body.should have_format(format)
end

Then /^the response should have the same content as the file "([^\"]*)"$/ do |name|
  if RUBY_VERSION =~ /^1\.8/
    @response.body.should == $app.fetch(TEMP_FILES[name]).data
  else
    @response.body.force_encoding('BINARY').should == $app.fetch(TEMP_FILES[name]).data.force_encoding('BINARY')
  end
end
