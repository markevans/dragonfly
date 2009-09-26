require File.dirname(__FILE__) + '/lib/imagetastic'

include Imagetastic

APP = Imagetastic::App.new
SAMPLES_DIR = '/Users/markevans/dev/samples/images'

APP.parameters_class.default_mime_type = 'image/jpeg'

APP.parameters_class.add_shortcut(/^\d+x\d+|^\d+x|^x\d+/) do |geometry|
  {
    :processing_method => :resize,
    :processing_options => {:geometry => geometry},
  }
end

available_uids = `find #{APP.datastore.root_path} ! -type d`.split("\n").map do |file|
  file.sub("#{APP.datastore.root_path}/", '')
end

puts "Loaded stuff from imagetastic irbrc"
puts "\nAvailable uids:\n"
puts available_uids
puts "\nAvailable sample images:\n"
puts Dir['samples/*']
puts