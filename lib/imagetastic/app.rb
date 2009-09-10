module Imagetastic
  class App
    
    def call(env)
      parameters = Imagetastic.url_handler.url_to_parameters(env['PATH_INFO'], env['QUERY_STRING'])
      image = Imagetastic.datastore.retrieve(parameters.uid)
      image = Imagetastic.processor.process(image, parameters.method, parameters.options)
      # image = Imagetastic.encoder.encode(image, params[:encoding])
      [200, {"Content-Type" => parameters.mime_type}, image]
    rescue UrlHandler::IncorrectSHA, UrlHandler::SHANotGiven => e
      [400, {"Content-Type" => "text/plain"}, [e]]
    end

  end
end
