require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'dragonfly'
include Dragonfly::Serializer

APP = Dragonfly.default_app.configure do
  use :imagemagick
  datastore :memory
end

class Model
  extend Dragonfly::Model
  attr_accessor :image_uid, :image_name, :image_width
  dragonfly_accessor :image
end

puts "Loaded stuff from dragonfly irbrc"
puts "\nAvailable sample images:\n"
puts Dir['samples/*']
puts "\nAvailable constants:\n"
puts "APP"
puts "\nModel:\n"
puts "dragonfly_accessor :image with image_name, image_width"
puts

