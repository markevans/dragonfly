require 'spec'
require 'rubygems'
require 'ruby-debug'

require File.dirname(__FILE__) + '/../lib/dragonfly'
$:.unshift(File.dirname(__FILE__))
require 'argument_matchers'
require 'simple_matchers'

SAMPLES_DIR = File.expand_path(File.dirname(__FILE__) + '/../samples') unless defined?(SAMPLES_DIR)

Spec::Runner.configure do |config|
  
end

def todo
  raise "TODO"
end