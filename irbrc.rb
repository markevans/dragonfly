require File.dirname(__FILE__) + '/lib/imagetastic'

include Imagetastic

@app = Imagetastic::App.new

def app
  @app
end

app.parameters_class.default_mime_type = 'image/jpeg'

app.parameters_class.add_shortcut(/^\d+x\d+|^\d+x|^x\d+/) do |geometry|
  {
    :processing_method => :resize,
    :processing_options => {:geometry => geometry},
  }
end

puts "Loaded stuff from imagetastic irbrc"
