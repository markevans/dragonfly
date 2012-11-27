require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../lib', __FILE__))
require 'dragonfly'
include Dragonfly::Serializer
APP = Dragonfly[:images].configure_with(:imagemagick)

# available_uids = `find #{APP.datastore.root_path} ! -type d`.split("\n").map do |file|
#   file.sub("#{APP.datastore.root_path}/", '')
# end

puts "Loaded stuff from dragonfly irbrc"
# puts "\nAvailable uids:\n"
# puts available_uids
puts "\nAvailable sample images:\n"
puts Dir['samples/*']
puts "\nAvailable constants:\n"
puts "APP"
puts
