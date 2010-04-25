def image_properties(image)
  data = case image
  when Dragonfly::TempObject then image.data
  when String then image
  end
  tempfile = Tempfile.new('image')
  tempfile.write(data)
  tempfile.close
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

def have_width(width)
  simple_matcher("have width #{width}"){|given| width.should === image_properties(given)[:width].to_i }
end

def have_height(height)
  simple_matcher("have height #{height}"){|given| height.should === image_properties(given)[:height].to_i }
end

def have_format(format)
  simple_matcher("have format #{format}"){|given| image_properties(given)[:format].should == format }
end
