module Imagetastic
  class App
    
    def call(env)
      it = Imagetastic::Instance.new
      parameters = it.url_handler.url_to_parameters(env['PATH_INFO'], env['QUERY_STRING'])
      image = it.datastore.retrieve(parameters.uid)
      image = it.processor.process(image, parameters.processing_method, parameters.processing_options)
      image = it.encoder.encode(image, parameters.mime_type, parameters.encoding)
      [200, {"Content-Type" => parameters.mime_type}, image]
    rescue UrlHandler::IncorrectSHA, UrlHandler::SHANotGiven => e
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    end

  end
end
