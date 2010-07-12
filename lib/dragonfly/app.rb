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
      @dos_protector = DosProtector.new(self, 'this is a secret yo')
    end
    
    include Loggable
    include Configurable
    
    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch
    def_delegator :server, :call
    
    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :default_format
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
    configurable_attr :fallback_mime_type, 'application/octet-stream'
    configurable_attr :path_prefix
    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret

    configuration_method :log

    attr_reader :analyser
    attr_reader :processor
    attr_reader :encoder

    def server
      @server ||= (
        app = self
        Rack::Builder.new do
          map app.mount_path do
            use DosProtector, app.secret if app.protect_from_dos_attacks
            run SimpleEndpoint.new(app)
          end
        end
      )
    end

    def new_job
      Job.new(self)
    end

    def endpoint(job=nil, &block)
      block ? RoutedEndpoint.new(self, &block) : JobEndpoint.new(job)
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
    
    def mount_path
      path_prefix.blank? ? '/' : path_prefix
    end
    
    def url_for(job)
      "#{path_prefix}/#{job.serialize}"
    end

    private
    
    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
