require File.dirname(__FILE__) + '/lib/imagetastic'

include Imagetastic

APP = Imagetastic::App.new
APP.configure do |c|
  c.datastore = Imagetastic::DataStorage::FileDataStore.new
  c.analyser do |a|
    a.register(Imagetastic::Analysis::RMagickAnalyser)
  end
  c.processor do |p|
    p.register(Imagetastic::Processing::RMagickProcessor)
  end
  c.encoder = Imagetastic::Encoding::RMagickEncoder.new
end
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

def new_image
  APP.create_object(File.new(Dir['samples/*'].first))
end

puts "Loaded stuff from imagetastic irbrc"
puts "\nAvailable uids:\n"
puts available_uids
puts "\nAvailable sample images:\n"
puts Dir['samples/*']
puts "\nAvailable methods:\n"
puts "new_image"
puts "\nAvailable constants:\n"
puts "APP"
puts