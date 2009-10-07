require File.dirname(__FILE__) + '/lib/imagetastic'

include Imagetastic

APP = Imagetastic::App.new
APP.configure do |c|
  c.datastore = Imagetastic::DataStorage::FileDataStore.new
  c.analyser do |a|
    a.register(Imagetastic::Analysis::RMagickAnalyser)
  end
  c.processor do |p|
    p.register(Imagetastic::Processing::RMagickProcessor)
  end
  c.encoder = Imagetastic::Encoding::RMagickEncoder.new
  c.default_mime_type = 'image/jpeg'
  c.add_shortcut(/^\d+x\d+|^\d+x|^x\d+/) do |geometry|
    {
      :processing_method => :resize,
      :processing_options => {:geometry => geometry},
    }
  end
end
APP.url_handler.protect_from_dos_attacks = false