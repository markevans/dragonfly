require File.dirname(__FILE__) + '/lib/dragonfly'
APP = Dragonfly[:images].configure_with(:rmagick)

available_uids = `find #{APP.datastore.root_path} ! -type d`.split("\n").map do |file|
  file.sub("#{APP.datastore.root_path}/", '')
end

def new_image
  APP.create_object(File.new(Dir['samples/*'].first))
end

puts "Loaded stuff from dragonfly irbrc"
puts "\nAvailable uids:\n"
puts available_uids
puts "\nAvailable sample images:\n"
puts Dir['samples/*']
puts "\nAvailable methods:\n"
puts "new_image"
puts "\nAvailable constants:\n"
puts "APP"
puts