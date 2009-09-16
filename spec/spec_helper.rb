require 'spec'
require 'rubygems'
require 'ruby-debug'

require File.dirname(__FILE__) + '/../lib/imagetastic'
$:.unshift(File.dirname(__FILE__))
require 'argument_matchers'
require 'simple_matchers'

Spec::Runner.configure do |config|
  
end

def todo
  raise "TODO"
end