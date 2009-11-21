$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'dragonfly'
require 'spec/expectations'
require 'test/unit/assertions'
require 'ruby-debug'
require File.dirname(__FILE__) + '/../../spec/image_matchers.rb'

# A hash of <name for reference> => <dragonfly uid> pairs
TEMP_FILES = {}

Dragonfly::App[:images].configure_with(Dragonfly::StandardConfiguration)
Dragonfly::App[:images].configure_with(Dragonfly::RMagickConfiguration)
Dragonfly::App[:files].configure_with(Dragonfly::StandardConfiguration)

SAMPLE_IMAGE_PATH = File.dirname(__FILE__)+'/../../samples/beach.png'

Before do
  # Remove temporary images
  TEMP_FILES.each do |name, uid|
    $app.datastore.destroy(uid)
    TEMP_FILES.delete(name)
  end
end

module MyHelpers
  
  def make_request(name, parameters = {})
    request = Rack::MockRequest.new($app)
    url = $app.url_handler.url_for(TEMP_FILES[name], parameters)
    @response = request.get(url)
  end
  
end

World(MyHelpers)