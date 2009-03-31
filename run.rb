require 'rubygems'
require 'rack'
require File.dirname(__FILE__) + '/lib/imagetastic'

puts "Running imagetastic..."
Rack::Handler::Mongrel.run Imagetastic::App.new, :Port => 9292