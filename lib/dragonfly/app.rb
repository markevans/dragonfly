require 'logger'
require 'forwardable'
require 'rack'

module Dragonfly
  class App

    class << self

      private :new # Hide 'new' - need to use 'instance'

      def instance(name)
        name = name.to_sym
        apps[name] ||= new(name)
      end

      alias [] instance

      private

      def apps
        @apps ||= {}
      end

    end

    def initialize(name)
      @name = name
      @analyser, @processor, @encoder, @generator = Analyser.new, Processor.new, Encoder.new, Generator.new
      [@analyser, @processor, @encoder, @generator].each do |obj|
        obj.use_same_log_as(self)
        obj.use_as_fallback_config(self)
      end
      @server = Server.new(self)
      @job_definitions = JobDefinitions.new
    end

    attr_reader :name

    include Configurable

    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch, :generate, :fetch_file, :fetch_url
    def_delegators :server, :call

    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
    configurable_attr :fallback_mime_type, 'application/octet-stream'
    configurable_attr :secret, 'secret yo'
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :trust_file_extensions, true
    configurable_attr :content_disposition
    configurable_attr :content_filename, Dragonfly::Response::DEFAULT_FILENAME

    attr_reader :analyser
    attr_reader :processor
    attr_reader :encoder
    attr_reader :generator
    attr_reader :server

    nested_configurable :server, :analyser, :processor, :encoder, :generator

    attr_accessor :job_definitions

    def new_job(content=nil, meta={})
      job_class.new(self, content, meta)
    end
    alias create new_job

    def endpoint(job=nil, &block)
      block ? RoutedEndpoint.new(self, &block) : JobEndpoint.new(job)
    end

    def job(name, &block)
      job_definitions.add(name, &block)
    end
    configuration_method :job

    def job_class
      @job_class ||= begin
        app = self
        Class.new(Job).class_eval do
          include app.analyser.analysis_methods
          include app.job_definitions
          include Job::OverrideInstanceMethods
          self
        end
      end
    end

    def store(object, opts={})
      temp_object = object.is_a?(TempObject) ? object : TempObject.new(object, opts[:meta] || {})
      datastore.store(temp_object, opts)
    end

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

    def response_headers
      @response_headers ||= {}
    end
    configuration_method :response_headers

    def define_url(&block)
      @url_proc = block
    end
    configuration_method :define_url

    def url_for(job, opts={})
      if @url_proc
        @url_proc.call(self, job, opts)
      else
        server.url_for(job, opts)
      end
    end

    def remote_url_for(uid, opts={})
      datastore.url_for(uid, opts)
    rescue NoMethodError => e
      raise NotImplementedError, "The datastore doesn't support serving content directly - #{datastore.inspect}"
    end

    def define_macro(mod, macro_name)
      already_extended = (class << mod; self; end).included_modules.include?(ActiveModelExtensions)
      mod.extend(ActiveModelExtensions) unless already_extended
      mod.register_dragonfly_app(macro_name, self)
    end

    def define_macro_on_include(mod, macro_name)
      app = self
      name = self.name
      (class << mod; self; end).class_eval do
        alias_method "included_without_dragonfly_#{name}_#{macro_name}", :included
        define_method "included_with_dragonfly_#{name}_#{macro_name}" do |mod|
          send "included_without_dragonfly_#{name}_#{macro_name}", mod
          app.define_macro(mod, macro_name)
        end
        alias_method :included, "included_with_dragonfly_#{name}_#{macro_name}"
      end
    end
    
    # Reflection
    def processor_methods
      processor.functions.keys
    end
    
    def generator_methods
      generator.functions.keys
    end
    
    def analyser_methods
      analyser.analysis_method_names
    end
    
    def job_methods
      job_definitions.definition_names
    end
    
    def inspect
      "<#{self.class.name} name=#{name.inspect} >"
    end
    
    # Deprecated methods
    def url_path_prefix=(thing)
      raise NoMethodError, "url_path_prefix is deprecated - please use url_format, e.g. url_format = '/media/:job/:basename.:format' - see docs for more details"
    end
    configuration_method :url_path_prefix=

    def url_suffix=(thing)
      raise NoMethodError, "url_suffix is deprecated - please use url_format, e.g. url_format = '/media/:job/:basename.:format' - see docs for more details"
    end
    configuration_method :url_suffix=

    def infer_mime_type_from_file_ext=(bool)
      raise NoMethodError, "infer_mime_type_from_file_ext is deprecated - please use trust_file_extensions = #{bool.inspect} instead"
    end
    configuration_method :infer_mime_type_from_file_ext=

    private

    attr_accessor :get_remote_url

    def saved_configs
      self.class.saved_configs
    end

    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
