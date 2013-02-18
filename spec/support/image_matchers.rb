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
    :width => width.to_i,
    :height => height.to_i,
    :depth => depth,
    :image_class => image_class,
    :size => size.to_i
  }
end

[:width, :height, :format, :size].each do |property|

  RSpec::Matchers.define "have_#{property}" do |value|
    match do |actual|
      value.should === image_properties(actual)[property]
    end
    failure_message_for_should do |actual|
      "expected image to have #{property} #{value.inspect}, but it had #{image_properties(actual)[property].inspect}"
    end
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
