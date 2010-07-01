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
      @analysers, @processors, @encoders = AnalyserList.new(self), ProcessorList.new(self), EncoderList.new(self)
    end
    
    include Configurable
    
    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch
    
    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :default_format
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
    configurable_attr :fallback_mime_type, 'application/octet-stream'
    configurable_attr :path_prefix, '/'
    configurable_attr :secret

    attr_reader :analysers
    attr_reader :processors
    attr_reader :encoders

    def call(env)
      request = Rack::Request.new(env)
      job_string = request.path.sub('/','')
      job = Job.deserialize(job_string, self)
      job.to_response
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      [404, {'Content-Type' => 'text/plain'}, ['Not found']]
    end

    def new_job
      Job.new(self)
    end

    def store(object, opts={})
      datastore.store(TempObject.new(object, opts))
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
    
    def url_for(job)
      "/#{job.serialize}"
    end

    private
    
    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
