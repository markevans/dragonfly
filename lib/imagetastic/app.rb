module Imagetastic
  class App
    
    def call(env)
      params = Imagetastic.url_handler.url_to_params(env['PATH_INFO'], env['QUERY_STRING'])
      image = Imagetastic.datastore.retrieve(params[:uid])
      image = Imagetastic.processor.process(image, params[:method], params[:options])
      # image = Imagetastic.encoder.encode(image, params[:encoding])
      [200, {"Content-Type" => params[:encoding][:mime_type]}, image]
    rescue UrlHandler::BadParams => e
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    end

  end
end
