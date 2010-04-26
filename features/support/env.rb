$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'dragonfly'
require 'spec/expectations'
require 'test/unit/assertions'
require File.dirname(__FILE__) + '/../../spec/image_matchers.rb'

# A hack as system calls weren't using my path
extra_paths = %w(/opt/local/bin)
ENV['PATH'] ||= ''
ENV['PATH'] += ':' + extra_paths.join(':')

# A hash of <name for reference> => <dragonfly uid> pairs
TEMP_FILES = {}

Dragonfly::App[:images].configure_with(Dragonfly::Config::RMagickImages)
Dragonfly::App[:files].configure do |c|
  c.register_analyser(Dragonfly::Analysis::FileCommandAnalyser)
  c.register_encoder(Dragonfly::Encoding::TransparentEncoder)
end

SAMPLE_IMAGE_PATH = File.dirname(__FILE__)+'/../../samples/beach.png'

Before do
  # Remove temporary images
  TEMP_FILES.each do |name, uid|
    $app.datastore.destroy(uid)
    TEMP_FILES.delete(name)
  end
end

module MyHelpers
  
  def make_request(name, *args)
    request = Rack::MockRequest.new($app)
    url = $app.url_for(TEMP_FILES[name], *args)
    @response = request.get(url)
  end
  
end

World(MyHelpers)