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
  # TODO: change!
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
      @analysers, @processors, @encoders = AnalyserList.new(self), ProcessorList.new(self), EncoderList.new(self)
      @job_manager = JobManager.new
      @parameters_class = Class.new(Parameters)
      @request_handler = RequestHandler.new
    end
    
    # @see Analysis::AnalyserList
    attr_reader :analysers
    # @see Processing::ProcessorList
    attr_reader :processors
    # @see Encoding::EncoderList
    attr_reader :encoders
    # @see JobManager
    attr_reader :job_manager
    # @see RequestHandler
    attr_reader :request_handler
    # @see Parameters
    attr_reader :parameters_class

    alias parameters parameters_class
    
    extend Forwardable
    def_delegator :datastore, :destroy
    
    include Configurable
    
    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :default_format
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
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
      request_handler.init!(env)
      job = request_handler.job
      temp_object = job.apply

      [200, {
        "Content-Type" => mime_type_for(parameters.format, temp_object),
        "Content-Length" => temp_object.size.to_s,
        "ETag" => parameters.unique_signature,
        "Cache-Control" => "public, max-age=#{cache_duration}"
        }, temp_object]
    rescue RequestHandler::IncorrectSHA, RequestHandler::SHANotGiven => e
      warn_with_info(e.message, env)
      [400, {"Content-Type" => "text/plain"}, [e.message]]
    rescue RequestHandler::UnknownUrl, DataStorage::DataNotFound => e
      [404, {"Content-Type" => 'text/plain'}, [e.message]]
    end

    # Create a temp_object from the object passed in
    # @param [String, File, Tempfile, TempObject] initialization_object the object holding the data
    # @return [ExtendedTempObject] a temp_object holding the data
    def create_object(initialization_object, opts={})
      ExtendedTempObject.new(self, initialization_object, opts)
    end

    def_delegators :job_manager, :define_job, :job_for
    configuration_method :define_job

    def_delegators :new_job, :fetch

    def new_job
      Job.new(self)
    end

    def generate(*args)
      create_object(processors.generate(*args))
    end

    # Store an object, using the configured datastore
    # @param [String, File, Tempfile, TempObject] object the object holding the data
    # @return [String] the uid assigned to it
    def store(object, opts={})
      datastore.store(create_object(object, opts))
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

    def register_mime_type(format, mime_type)
      registered_mime_types[file_ext_string(format)] = mime_type
    end
    configuration_method :register_mime_type

    def registered_mime_types
      @registered_mime_types ||= Rack::Mime::MIME_TYPES.dup
    end
    
    def mime_type_for(format)
      registered_mime_types[file_ext_string(format)]
    end

    private

    def warn_with_info(message, env)
      log.warn "Got error: #{message}\nPath was #{env['PATH_INFO'].inspect} and query was #{env['QUERY_STRING'].inspect}"
    end
    
    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
