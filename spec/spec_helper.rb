require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'dragonfly'
require 'fileutils'

require 'webmock/rspec'

# Requires supporting files with custom matchers and macros, etc,
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SAMPLES_DIR = Pathname.new(File.expand_path(File.dirname(__FILE__) + '/../samples')) unless defined?(SAMPLES_DIR)

def todo
  raise "TODO"
end

require 'logger'
LOG_FILE = 'tmp/test.log' unless defined?(LOG_FILE)
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
  time = Time.now
  app = Dragonfly::App.send(:new, "test_#{time.sec}_#{time.usec}".to_sym)
  app.log = Logger.new(LOG_FILE)
  app.datastore.root_path = 'tmp/file_data_store_test'
  app
end

def suppressing_stderr
  original_stderr = $stderr.dup
  tempfile = Tempfile.new('stderr')
  $stderr.reopen(tempfile) rescue
  yield
ensure
  tempfile.close!
  $stderr.reopen(original_stderr)
end
