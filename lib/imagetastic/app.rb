module Imagetastic
  class App
    
    def call(env)
      params = Imagetastic.url_handler.url_to_params(env['PATH_INFO'], env['QUERY_STRING'])
    #   image = Imagetastic.datastore.retrieve(image_uid)
    #   processed_image = Imagetastic.image_processor.process(image, params)
      [200, {"Content-Type" => params[:encoding][:mime_type]}, [params.inspect]]
    # rescue UrlHandler::BadParams => e
    #   [400, {"Content-Type" => "text/plain"}, [e.message]]
    end

  end
end
