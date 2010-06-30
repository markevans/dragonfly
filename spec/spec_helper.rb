require 'rubygems'
require 'spec'
require 'rack'

require File.dirname(__FILE__) + '/../lib/dragonfly'
$:.unshift(File.dirname(__FILE__))
require 'argument_matchers'
require 'simple_matchers'
require 'image_matchers'

# A hack as system calls weren't using my path
extra_paths = %w(/opt/local/bin)
ENV['PATH'] ||= ''
ENV['PATH'] += ':' + extra_paths.join(':')

SAMPLES_DIR = File.expand_path(File.dirname(__FILE__) + '/../samples') unless defined?(SAMPLES_DIR)

Spec::Runner.configure do |config|
  
end

def todo
  raise "TODO"
end

require 'logger'
def mock_app
  mock('app',
    :datastore => mock('datastore', :store => 'some_uid', :retrieve => ["SOME_DATA", {}], :destroy => nil),
    :processors => mock('processors', :process => "SOME_PROCESSED_DATA"),
    :encoders => mock('encoders', :encode => "SOME_ENCODED_DATA"),
    :analysers => mock('analysers', :analyse => "some_result"),
    :log => Logger.new($stderr)
  )
end
