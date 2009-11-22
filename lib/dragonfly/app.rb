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
  # @example Example configuration options:
  #
  # Dragonfly::App[:images].configure do |c|
  #   c.datastore = MyEC2DataStore.new                     # See DataStorage::Base for how to create a custom data store
  #   c.register_analyser(Analysis::RMagickAnalyser)       # See Analysis::Base for how to create a custom analyser
  #   c.register_processor(Processing::RMagickProcessor)   # See Processing::Base for how to create a custom analyser
  #   c.register_encoder(Encoding::RMagickEncoder)         # See Encoding::Base for how to create a custom encoder
  #   c.log = Logger.new('/tmp/my.log')
  #   c.cache_duration = 3000                              # seconds
  # end
  #
  # @example Configuration including nested items
  #
  # Dragonfly::App[:images].configure do |c|
  #   # ...
  #   c.datastore.configure do |d|    # configuration depends on which data store you use
  #     # ...
  #   end
  #   c.parameters.configure do |p|   # see Parameters (class methods)
  #     # ...
  #   end
  #   c.url_handler.configure do |u|   # see UrlHandler
  #     # ...
  #   end
  # end
  #
  class App
    
    
    class << self
      
      private :new # Hide 'new' - need to use 'instance'
      
      # Get / create a Dragonfly App.
      #
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
      @analysers = Analysis::AnalyserList.new
      @processors = Processing::ProcessorList.new
      @encoders = Encoding::EncoderList.new
      @parameters_class = Class.new(Parameters)
      @url_handler = UrlHandler.new(@parameters_class)
      initialize_temp_object_class
    end
    
    # @see Analysis::AnalyserList
    attr_reader :analysers
    # @see Processing::ProcessorList
    attr_reader :processors
    # @see Encoding::EncoderList
    attr_reader :encoders
    # @see UrlHandler
    attr_reader :url_handler
    # @see Parameters
    attr_reader :parameters_class
    # @see TempObject, and ExtendedTempObject
    attr_reader :temp_object_class

    alias parameters parameters_class
    
    extend Forwardable
    def_delegator :url_handler, :url_for
    
    include Configurable
    
    configurable_attr :datastore do DataStorage::Base.new end
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :cache_duration, 3600*24*365 # Defaults to 1 year
    configurable_attr :fallback_mime_type, 'application/octet-stream'    
    
    # The call method required by Rack to run.
    #
    # @param env the Rack env hash
    # @return [Array] a Rack response:
    #
    #   - 200 status if all ok
    #
    #   - 400 if url recognised but parameters incorrect
    #
    #   - 404 if url not recognised / data not found.
    #
    # See the Rack documentation for more details
    def call(env)
      parameters = url_handler.url_to_parameters(env['PATH_INFO'], env['QUERY_STRING'])
      temp_object = fetch(parameters.uid, parameters)
      [200, {
        "Content-Type" => temp_object.mime_type || fallback_mime_type,
        "Content-Length" => temp_object.size.to_s,
        "ETag" => parameters.unique_signature,
        "Cache-Control" => "public, max-age=#{cache_duration}"
        }, temp_object]
    rescue UrlHandler::IncorrectSHA, UrlHandler::SHANotGiven => e
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    rescue UrlHandler::UnknownUrl, DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end

    # Store an object, using the configured datastore
    # @param [String, File, Tempfile, TempObject] object the object holding the data
    # @return [String] the uid assigned to it
    def store(object)
      datastore.store(create_object(object))
    end

    # Fetch an object from the database and optionally transform
    #
    # Note that the arguments passed in to transform are as defined by the
    # parameter shortcuts (see Parameter class methods)
    # @param [String] uid the string uid corresponding to the stored data object
    # @param [*args [optional]] shortcut_args the shortcut args for transforming the object 
    # @return [ExtendedTempObject] a temp_object holding the data
    # @example 
    # app = Dragonfly::App[:images]
    # app.fetch('abcd1234')             # returns a temp_object with exactly the data that was originally stored
    # app.fetch('abcd1234', '20x20!')   # returns a transformed temp_object, in this case with image data resized to 20x20
    # @see Parameters
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

    def register_analyser(*args, &block)
      analysers.register(*args, &block)
    end
    configuration_method :register_analyser

    def register_processor(*args, &block)
      processors.register(*args, &block)
    end
    configuration_method :register_processor

    def register_encoder(*args, &block)
      encoders.register(*args, &block)
    end
    configuration_method :register_encoder

    private
    
    def initialize_temp_object_class
      @temp_object_class = Class.new(ExtendedTempObject)
      @temp_object_class.app = self
    end

  end
end
