When /^I look at the generated (.+) image$/ do |image_name|
  page.body =~ /src="(.+?#{image_name}.+?)"/
  url = $1
  visit(url)
end

Then /^I should see a (.+) image of size (.+)$/ do |format, size|
  tempfile = Tempfile.new('wicked')
  tempfile.write page.body
  tempfile.close
  output = `identify #{tempfile.path}`.split(' ')
  output[1].should == 'JPEG'
  output[2].should == '200x100'
end
