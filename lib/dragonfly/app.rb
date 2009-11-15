require 'logger'
require 'forwardable'

module Dragonfly

  # A Dragonfly App is the rack app which holds everything together.
  # You can have as many app instances as you want, and they all have
  # completely separate configuration.
  # Each App has a name.
  # @example
  # Dragonfly::App[:images]   # => creates a new app named :images
  # Dragonfly::App[:images]   # => returns the :images app
  # Dragonfly::App[:ocr]      # => creates a new app named :ocr
  #
  # # The two apps can be differently configured
  # Dragonfly::App[:images].parameters.default_format = :jpg
  # Dragonfly::App[:ocr].parameters.default_format = :tif
  #
  # @example Configurable options:
  #
  # Dragonfly::App[:images].configure do |c|
  #   c.datastore = MyEC2DataStore.new           # See DataStorage::Base for how to create a custom data store
  #   c.encoder = Encoding::RMagickEncoder.new   # See Encoding::Base for how to create a custom encoder
  #   c.log = Logger.new('/tmp/my.log')          
  #   c.cache_duration = 3000                    # seconds
  # end
  #
  #
  class App
    
    
    class << self
      
      private :new # Hide 'new' - need to use 'instance'
      
      # Get / create a Dragonfly App.
      # Rather than using 'new', use this method to create / refer to each app.
      #
      # @param [Symbol] name the name of the App
      # @return [App] either the named App or a new one with that name
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
    
    # @see Analysis::Analyser
    attr_reader :analyser
    # @see Processing::Processor
    attr_reader :processor
    # @see Encoding::Base
    attr_reader :encoder
    # @see UrlHandler
    attr_reader :url_handler
    # @see Parameters
    attr_reader :parameters_class

    alias parameters parameters_class
    
    extend Forwardable
    def_delegator :url_handler, :url_for
    
    include Configurable
    
    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :encoder do Encoding::Base.new end
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :cache_duration, 3600*24*365 # Defaults to 1 year
    
    # The call method required by Rack to run
    # see the Rack documentation for more details
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
    rescue UrlHandler::UnknownUrl, DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end

    # Fetch an object from the database and optionally transform
    # @param [String] uid the string uid corresponding to the stored data object
    # @param [*args [optional]] shortcut_args the shortcut args for transforming the object 
    # @return [ExtendedTempObject] a temp_object holding the data
    # @example 
    # app = Dragonfly::App[:images]
    # app.fetch('abcd1234')             # returns a temp_object with exactly the data that was originally stored
    # app.fetch('abcd1234', '20x20!')   # returns a transformed temp_object, in this case with image data resized to 20x20
    def fetch(uid, *args)
      temp_object = temp_object_class.new(datastore.retrieve(uid))
      temp_object.transform(*args)
    end

    # Create a temp_object from the object passed in
    # @param [String, File, Tempfile, TempObject] initialization_object the object holding the data
    # @return [ExtendedTempObject] a temp_object holding the data
    def create_object(initialization_object)
      temp_object_class.new(initialization_object)
    end

    private
    
    # @private
    attr_reader :temp_object_class
    
    def initialize_temp_object_class
      @temp_object_class = Class.new(ExtendedTempObject)
      @temp_object_class.app = self
    end

  end
end
