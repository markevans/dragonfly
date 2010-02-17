When /^I look at the generated (.+) image$/ do |image_name|
  url = page.body[/[^\s]+#{image_name}[^\s]+/]
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
