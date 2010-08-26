$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'dragonfly'
require 'spec/expectations'
require 'test/unit/assertions'
require File.dirname(__FILE__) + '/../../spec/image_matchers.rb'

ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../..")

# A hash of <name for reference> => <dragonfly uid> pairs
TEMP_FILES = {}

Dragonfly[:images].configure_with(:rmagick)
Dragonfly[:files].configure do |c|
  c.analyser.register(Dragonfly::Analysis::FileCommandAnalyser)
end

SAMPLE_IMAGE_PATH = File.dirname(__FILE__)+'/../../samples/beach.png'

Before do
  # Remove temporary images
  TEMP_FILES.each do |name, uid|
    $app.datastore.destroy(uid)
    TEMP_FILES.delete(name)
  end
end

AfterStep do |scenario|
  Dir["#{ROOT_PATH}/Gemfile*.lock"].each{|f| FileUtils.rm_f(f) }
end

module MyHelpers
  
  def make_request(job)
    request = Rack::MockRequest.new($app)
    @response = request.get(job.url)
  end
  
end

World(MyHelpers)