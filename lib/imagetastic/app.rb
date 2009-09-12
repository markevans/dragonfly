module Imagetastic
  class App
    
    def call(env)
      it = Imagetastic::Instance.new
      parameters = it.url_handler.url_to_parameters(env['PATH_INFO'], env['QUERY_STRING'])
      temp_object = it.datastore.retrieve(parameters.uid)
      temp_object = it.processor.process(temp_object, parameters.processing_method, parameters.processing_options)
      temp_object = it.encoder.encode(temp_object, parameters.mime_type, parameters.encoding)
      [200, {"Content-Type" => parameters.mime_type}, temp_object]
    rescue UrlHandler::IncorrectSHA, UrlHandler::SHANotGiven => e
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    end

  end
end
