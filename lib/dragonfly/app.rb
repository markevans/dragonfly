require 'logger'
require 'forwardable'
require 'rack'

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
      @analyser, @processor, @encoder, @generator = Analyser.new, Processor.new, Encoder.new, Generator.new
      @analyser.use_same_log_as(self)
      @processor.use_same_log_as(self)
      @encoder.use_same_log_as(self)
      @generator.use_same_log_as(self)
      @dos_protector = DosProtector.new(self, 'this is a secret yo')
      @job_definitions = JobDefinitions.new
    end
    
    include Configurable
    
    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch, :generate, :fetch_file
    def_delegator :server, :call
    
    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :default_format
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
    configurable_attr :fallback_mime_type, 'application/octet-stream'
    configurable_attr :path_prefix
    configurable_attr :protect_from_dos_attacks, true
    configurable_attr :secret
    configurable_attr :sha_length, 16
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :infer_mime_type_from_file_ext, true

    attr_reader :analyser
    attr_reader :processor
    attr_reader :encoder
    attr_reader :generator
    
    attr_accessor :job_definitions

    def server
      @server ||= (
        app = self
        Rack::Builder.new do
          map app.mount_path do
            use DosProtector, app.secret, :sha_length => app.sha_length if app.protect_from_dos_attacks
            run SimpleEndpoint.new(app)
          end
        end.to_app
      )
    end

    def new_job(content=nil)
      content ? Job.new(self, TempObject.new(content)) : Job.new(self)
    end

    def endpoint(job=nil, &block)
      block ? RoutedEndpoint.new(self, &block) : JobEndpoint.new(job)
    end

    def job(name, &block)
      job_definitions.add(name, &block)
    end
    configuration_method :job

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

    def register_generator(*args, &block)
      generator.register(*args, &block)
    end
    configuration_method :register_generator

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
    
    def resolve_mime_type(temp_object)
      mime_type_for(temp_object.format)                                   ||
        (mime_type_for(temp_object.ext) if infer_mime_type_from_file_ext) ||
        analyser.analyse(temp_object, :mime_type)                         ||
        mime_type_for(analyser.analyse(temp_object, :format))             ||
        fallback_mime_type
    end

    def mount_path
      path_prefix.blank? ? '/' : path_prefix
    end
    
    def url_for(job)
      path = "#{path_prefix}#{SimpleEndpoint.job_to_path(job)}"
      if protect_from_dos_attacks
        query_string = DosProtector.required_params_for(path, secret, :sha_length => sha_length).map{|k,v|
          "#{k}=#{v}"
        }.join('&')
        path << "?#{query_string}"
      end
      path
    end

    def define_macro(mod, macro_name)
      already_extended = (class << mod; self; end).included_modules.include?(ActiveModelExtensions)
      mod.extend(ActiveModelExtensions) unless already_extended
      mod.register_dragonfly_app(macro_name, self)
    end

    def define_macro_on_include(mod, macro_name)
      app = self
      (class << mod; self; end).class_eval do
        alias included_without_dragonfly included
        define_method :included_with_dragonfly do |mod|
          included_without_dragonfly(mod)
          app.define_macro(mod, macro_name)
        end
        alias included included_with_dragonfly
      end
    end

    private
    
    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
