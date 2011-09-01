def image_properties(image)
  if image.is_a?(Tempfile)
    tempfile = image
  else
    tempfile = Tempfile.new('image')
    tempfile.binmode
    tempfile.write(image.is_a?(Dragonfly::TempObject) ? image.data : image)
    tempfile.close
  end
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

RSpec::Matchers.define :have_width do |width|
  match do |given|
    width.should === image_properties(given)[:width].to_i
  end
end

RSpec::Matchers.define :have_height do |height|
  match do |given|
    height.should === image_properties(given)[:height].to_i
  end
end

RSpec::Matchers.define :have_format do |format|
  match do |given|
    image_properties(given)[:format].should == format
  end
end

RSpec::Matchers.define :have_size do |size|
  match do |given|
    image_properties(given)[:size].should == size
  end
end

RSpec::Matchers.define :equal_image do |other|
  match do |given|
    image_data = given.open.read
    other_image_data = other.open.read
    given.close
    other.close
    image_data == other_image_data
  end
end
