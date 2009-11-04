$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'dragonfly'
require 'spec/expectations'
require 'test/unit/assertions'
require 'ruby-debug'
require File.dirname(__FILE__) + '/image_helpers.rb'
require File.dirname(__FILE__) + '/../../spec/image_matchers.rb'

# A hash of <name for reference> => <dragonfly uid> pairs
TEMP_IMAGES = {}

APP = Dragonfly::App[:images]
APP.configure do |c|
  c.datastore = Dragonfly::DataStorage::FileDataStore.new
  c.analyser do |a|
    a.register(Dragonfly::Analysis::RMagickAnalyser)
  end
  c.processor do |p|
    p.register(Dragonfly::Processing::RMagickProcessor)
  end
  c.encoder = Dragonfly::Encoding::RMagickEncoder.new
end

SAMPLE_IMAGE_PATH = File.dirname(__FILE__)+'/../../samples/beach.png'

Before do
  # Remove temporary images
  TEMP_IMAGES.each do |name, uid|
    APP.datastore.destroy(uid)
    TEMP_IMAGES.delete(name)
  end
end

World(ImageHelpers)