require 'logger'

module Imagetastic
  class Instance
    
    include Configurable
    
    configurable_attr(:datastore){DataStorage::FileDataStore.new}
    
    configurable_attr(:analyser){Processing::Ragick::Analyser.new}
    
    configurable_attr(:processor){Processing::RMagick::Processor.new}
    
    configurable_attr(:encoder){Processing::RMagick::Encoder.new}
    
    configurable_attr(:url_handler){UrlHandler.new}
    
    configurable_attr(:log){Logger.new('/var/tmp/imagetastic.log')}

  end
end
