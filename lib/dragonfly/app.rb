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
      self.log = proc{ Logger.new('/var/tmp/dragonfly.log') }
      @analyser, @processor, @encoder = Analyser.new, Processor.new, Encoder.new
      @analyser.use_same_log_as(self)
      @processor.use_same_log_as(self)
      @encoder.use_same_log_as(self)
    end
    
    include Loggable
    include Configurable
    
    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch
    
    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :default_format
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
    configurable_attr :fallback_mime_type, 'application/octet-stream'
    configurable_attr :path_prefix, ''
    configurable_attr :secret

    configuration_method :log

    attr_reader :analyser
    attr_reader :processor
    attr_reader :encoder

    def call(env)
      request = Rack::Request.new(env)
      
      job = extract_job(request.path)
      if job
        job.to_response
      else
        not_found_response('X-Cascade' => 'pass')
      end
    rescue Serializer::BadString, Job::InvalidArray => e
      log.warn(e.message)
      not_found_response
    end

    def new_job
      Job.new(self)
    end

    def endpoint(job=nil, &block)
      block ? RoutedEndpoint.new(self, &block) : SimpleEndpoint.new(job)
    end

    def store(object, opts={})
      datastore.store(TempObject.new(object, opts))
    end

    def register_analyser(*args, &block)
      analyser.register(*args, &block)
    end
    configuration_method :register_analyser

    def register_processor(*args, &block)
      processor.register(*args, &block)
    end
    configuration_method :register_processor

    def register_encoder(*args, &block)
      encoder.register(*args, &block)
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
      "#{path_prefix}/#{job.serialize}"
    end

    private

    def extract_job(path)
      if path =~ %r(^#{path_prefix}/(.+))
        Job.deserialize($1, self)
      end
    end
    
    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

    def not_found_response(extra_headers={})
      [404, {'Content-Type' => 'text/plain'}.merge(extra_headers), ['Not found']]
    end

  end
end
