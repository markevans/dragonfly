Given /^an album "(.+)" with attached file "(.+)"$/ do |name, filename|
  Album.create! :name => name, :cover_image => Rails.root.join('../../../samples', filename)
end

When /^I look at the generated image$/ do
  page.body =~ %r{src="(/media[^"]+?)"}
  url = $1
  visit(url)
end

When /^I look at the original image$/ do
  page.body =~ %r{src="(/system[^"]+?)"}
  url = $1
  visit(url)
end

Then /^I should see a (.+) image of size (.+)$/ do |format, size|
  tempfile = Tempfile.new('wicked')
  tempfile.binmode
  tempfile.write page.source
  tempfile.close
  output = `identify #{tempfile.path}`.split(' ')
  output[1].should == format
  output[2].should == size
end

Then /^the hash shown in the view should be the same as in the spec$/ do
  @album = Album.last
  image_url = @album.cover_image.thumb('200x100!').url
  page.should have_css("img[src='#{image_url}']")
end
