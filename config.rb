require File.dirname(__FILE__) + '/lib/dragonfly'

include Dragonfly

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
    u.protect_from_dos_attacks = false
  end
end
