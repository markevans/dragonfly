$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../../lib')
require 'imagetastic'
require 'spec/expectations'
require 'test/unit/assertions'
require 'ruby-debug'
require File.dirname(__FILE__) + '/image_helpers.rb'

# A hash of <name for reference> => <imagetastic uid> pairs
TEMP_IMAGES = {}

APP = Imagetastic::App[:images]
APP.configure do |c|
  c.datastore = Imagetastic::DataStorage::FileDataStore.new
  c.analyser do |a|
    a.register(Imagetastic::Analysis::RMagickAnalyser)
  end
  c.processor do |p|
    p.register(Imagetastic::Processing::RMagickProcessor)
  end
  c.encoder = Imagetastic::Encoding::RMagickEncoder.new
end

SAMPLE_IMAGE_PATH = File.dirname(__FILE__)+'/../../samples/beach.png'

Before do
  # Remove temporary images
  TEMP_IMAGES.each do |name, uid|
    APP.datastore.destroy(uid)
    TEMP_IMAGES.delete(name)
  end
end

World(Imagetastic::Utils)
World(ImageHelpers)