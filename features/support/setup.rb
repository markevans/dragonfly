ROOT_PATH = File.expand_path(File.dirname(__FILE__) + "/../..")

require ROOT_PATH + '/spec/support/image_matchers.rb'

# A hash of <name for reference> => <dragonfly uid> pairs
TEMP_FILES = {}

Dragonfly[:images].configure_with(:imagemagick)
Dragonfly[:files].configure do |c|
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
