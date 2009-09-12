require 'logger'

module Imagetastic
  class App
    
    include Configurable
    
    configurable_attr :datastore do DataStorage::FileDataStore.new end
    
    configurable_attr :analyser do raise "Not implemented yet!!!" end
    
    configurable_attr :processor do RMagick::Processor.new end
    
    configurable_attr :encoder do RMagick::Encoder.new end
    
    configurable_attr :url_handler do UrlHandler.new end
    
    configurable_attr :log do Logger.new('/var/tmp/imagetastic.log') end
    
    
    def call(env)
      parameters = url_handler.url_to_parameters(env['PATH_INFO'], env['QUERY_STRING'])
      temp_object = datastore.retrieve(parameters.uid)
      temp_object = processor.process(temp_object, parameters.processing_method, parameters.processing_options)
      temp_object = encoder.encode(temp_object, parameters.mime_type, parameters.encoding)
      [200, {"Content-Type" => parameters.mime_type}, temp_object]
    rescue UrlHandler::IncorrectSHA, UrlHandler::SHANotGiven => e
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    end

  end
end
