require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'dragonfly'
include Dragonfly::Serializer

APP = Dragonfly[:images].configure do
  use :imagemagick
  datastore :memory
end

puts "Loaded stuff from dragonfly irbrc"
puts "\nAvailable sample images:\n"
puts Dir['samples/*']
puts "\nAvailable constants:\n"
puts "APP"
puts
