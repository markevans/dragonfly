def image_properties(image)
  details = `identify #{image.path}`
  raise "couldn't identify #{image.path} in image_properties" if details.empty?
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
    given.data == other.data
  end
end
