require 'rubygems'
require 'spec'
require 'rack'

require File.dirname(__FILE__) + '/../lib/dragonfly'
$:.unshift(File.dirname(__FILE__))
require 'argument_matchers'
require 'simple_matchers'
require 'image_matchers'

ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/..") unless defined?(ROOT_PATH)

# A hack as system calls weren't using my path
extra_paths = %w(/opt/local/bin)
ENV['PATH'] ||= ''
ENV['PATH'] += ':' + extra_paths.join(':')

SAMPLES_DIR = File.expand_path(File.dirname(__FILE__) + '/../samples') unless defined?(SAMPLES_DIR)

Spec::Runner.configure do |c|
  c.after(:all){ Dir["#{ROOT_PATH}/Gemfile*.lock"].each{|f| FileUtils.rm_f(f) } }
end

def todo
  raise "TODO"
end

require 'logger'
LOG_FILE = File.dirname(__FILE__) + '/spec.log' unless defined?(LOG_FILE)
FileUtils.rm_rf(LOG_FILE)
def mock_app(extra_stubs={})
  mock('app', {
    :datastore => mock('datastore', :store => 'some_uid', :retrieve => ["SOME_DATA", {}], :destroy => nil),
    :processor => mock('processor', :process => "SOME_PROCESSED_DATA"),
    :encoder => mock('encoder', :encode => "SOME_ENCODED_DATA"),
    :analyser => mock('analyser', :analyse => "some_result", :analysis_methods => Module.new),
    :generator => mock('generator', :generate => "SOME_GENERATED_DATA"),
    :log => Logger.new(LOG_FILE),
    :cache_duration => 10000,
    :job_definitions => Module.new
  }.merge(extra_stubs)
  )
end

def test_app
  Dragonfly::App.send(:new)
end
