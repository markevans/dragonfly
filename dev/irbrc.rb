require "rubygems"
require "bundler/setup"
$:.unshift(File.expand_path('../../lib', __FILE__))
require 'dragonfly'
require 'pry'

APP = Dragonfly.app.configure do
  plugin :imagemagick
  datastore :memory
end

class Model
  extend Dragonfly::Model
  attr_accessor :image_uid, :image_name, :image_width, :small_image_uid
  dragonfly_accessor :image
  dragonfly_accessor :small_image
end

def reload
  self.class.send(:remove_const, :APP)
  Dragonfly.constants.each do |const|
    Dragonfly.send(:remove_const, const)
  end
  $LOADED_FEATURES.grep(/dragonfly/).each do |path|
    load path
  end
  nil
end
alias reload! reload

puts "Loaded stuff from dragonfly irbrc"
puts "\nAvailable sample images:\n"
puts Dir['samples/*']
puts "\nAvailable constants:\n"
puts "APP"
puts "\nModel:\n"
puts "dragonfly_accessor :image with image_name, image_width"
puts

