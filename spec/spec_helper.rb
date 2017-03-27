require "rubygems"
require "bundler"
require 'active_record'
Bundler.setup(:default, :test)

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'dragonfly'
require 'fileutils'
require 'tempfile'
require 'webmock/rspec'
require 'pry'

# Requires supporting files with custom matchers and macros, etc,
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

SAMPLES_DIR = Pathname.new(File.expand_path('../../samples', __FILE__))

RSpec.configure do |c|
  c.include ModelHelpers
  c.include RackHelpers
end

def todo
  raise "TODO"
end

require 'logger'
LOG_FILE = 'tmp/test.log'
FileUtils.rm_rf(LOG_FILE)
Dragonfly.logger = Logger.new(LOG_FILE)

RSpec.configure do |c|
  c.after(:each) do
    Dragonfly::App.destroy_apps
  end
end

def test_app(name=nil)
  app = Dragonfly::App.instance(name)
  app.datastore = Dragonfly::MemoryDataStore.new
  app.secret = "test secret"
  app
end

def test_imagemagick_app
  test_app.configure do
    generator :convert, Dragonfly::ImageMagick::Generators::Convert.new
    processor :convert, Dragonfly::ImageMagick::Processors::Convert.new
    analyser :image_properties, Dragonfly::ImageMagick::Analysers::ImageProperties.new
  end
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db
  ActiveRecord::Schema.define(:version => 1) do
    create_table :relational_dragonflies do |t|
      t.binary :data
      t.string :meta
      t.timestamps
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class RelationalDragonfly < ActiveRecord::Base
end