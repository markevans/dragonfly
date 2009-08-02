module Imagetastic
  class App
    
    def call(env)
      params = Imagetastic.url_handler.query_to_params(env['QUERY_STRING'])
      [200, {"Content-Type" => "text/html"}, ["This is imagetastic!"]]
    rescue UrlHandler::BadParams => e
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    end

  end
end