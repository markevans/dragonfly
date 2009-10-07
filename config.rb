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
  c.parameters do |p|
    p.default_mime_type = 'image/jpeg'
    p.add_shortcut(/^\d+x\d+|^\d+x|^x\d+/) do |geometry|
      {
        :processing_method => :resize,
        :processing_options => {:geometry => geometry},
      }
    end
  end
  c.url_handler do |u|
    u.protect_from_dos_attacks = true
  end
end
