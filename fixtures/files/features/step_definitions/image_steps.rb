When /^I look at the generated (.+) image$/ do |image_name|
  page.body =~ %r{src="(/media[^"]+?)"}
  url = $1
  visit(url)
end

Then /^I should see a (.+) image of size (.+)$/ do |format, size|
  tempfile = Tempfile.new('wicked')
  page.body.force_encoding('UTF-8').encode! if page.body.respond_to?(:force_encoding) # For some reason need this on Ruby 1.9.2
  tempfile.write page.body
  tempfile.close
  output = `identify #{tempfile.path}`.split(' ')
  output[1].should == format
  output[2].should == size
end
