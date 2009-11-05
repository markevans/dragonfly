require 'logger'
require 'forwardable'

module Dragonfly
  class App
    
    class << self
      
      private :new # Hide 'new' - need to use 'instance'
      
      def instance(name)
        apps[name] ||= new
      end
      
      alias [] instance
      
      private
      
      def apps
        @apps ||= {}
      end
            
    end
    
    def initialize
      @analyser = Analysis::Analyser.new
      @processor = Processing::Processor.new
      @parameters_class = Class.new(Parameters)
      @url_handler = UrlHandler.new(@parameters_class)
      initialize_temp_object_class
    end
    
    attr_reader :analyser,
                :processor,
                :encoder,
                :url_handler,
                :parameters_class,
                :temp_object_class

    alias parameters parameters_class
    
    # Just for convenience so the user doesn't have to use url_handler
    extend Forwardable
    def_delegator :url_handler, :url_for
    
    include Configurable
    
    configurable_attr :datastore do DataStorage::Base.new end
    configurable_attr :encoder do Encoding::Base.new end
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :cache_duration, 3000
    
    def call(env)
      parameters = url_handler.url_to_parameters(env['PATH_INFO'], env['QUERY_STRING'])
      temp_object = fetch(parameters.uid, parameters)
      [200, {
        "Content-Type" => temp_object.mime_type,
        "Content-Length" => temp_object.size.to_s,
        "ETag" => parameters.unique_signature,
        "Cache-Control" => "public, max-age=#{cache_duration}"
        }, temp_object]
    rescue UrlHandler::IncorrectSHA, UrlHandler::SHANotGiven => e
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    end

    def fetch(uid, *args)
      temp_object = temp_object_class.new(datastore.retrieve(uid))
      temp_object.transform(*args)
    end

    def create_object(initialization_object)
      temp_object_class.new(initialization_object)
    end

    private
    
    def initialize_temp_object_class
      @temp_object_class = Class.new(ExtendedTempObject)
      @temp_object_class.app = self
    end

  end
end
