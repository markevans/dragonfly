ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../..")

require ROOT_PATH + '/spec/support/image_matchers.rb'

# A hash of <name for reference> => <dragonfly uid> pairs
TEMP_FILES = {}

root_path = ROOT_PATH + '/tmp/dragonfly_cukes'
logger = Logger.new(ROOT_PATH + '/tmp/dragonfly_cukes.log')

Dragonfly[:images].configure_with(:imagemagick).configure do |c|
  c.datastore.root_path = root_path
  c.log = logger
end

Dragonfly[:files].configure do |c|
  c.datastore.root_path = root_path
  c.log = logger
  c.analyser.register(Dragonfly::Analysis::FileCommandAnalyser)
end

SAMPLE_IMAGE_PATH = ROOT_PATH + '/samples/beach.png'

Before do
  # Remove temporary images
  TEMP_FILES.each do |name, uid|
    $app.datastore.destroy(uid)
    TEMP_FILES.delete(name)
  end
end

module MyHelpers
  
  def make_request(job)
    request = Rack::MockRequest.new($app)
    @response = request.get(job.url)
  end
  
end

World(MyHelpers)
