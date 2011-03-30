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
      [@analyser, @processor, @encoder, @generator].each do |obj|
        obj.use_same_log_as(self)
        obj.use_as_fallback_config(self)
      end
      @server = Server.new(self)
      @job_definitions = JobDefinitions.new
    end

    include Configurable

    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch, :generate, :fetch_file, :fetch_url
    def_delegators :server, :call, :url_for

    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
    configurable_attr :fallback_mime_type, 'application/octet-stream'
    configurable_attr :secret, 'secret yo'
    configurable_attr :log do Logger.new('/var/tmp/dragonfly.log') end
    configurable_attr :infer_mime_type_from_file_ext, true
    configurable_attr :content_disposition
    configurable_attr :content_filename, Response::DEFAULT_FILENAME

    attr_reader :analyser
    attr_reader :processor
    attr_reader :encoder
    attr_reader :generator
    attr_reader :server

    configuration_method :analyser
    configuration_method :processor
    configuration_method :encoder
    configuration_method :generator

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

    def attachment_class
      @attachment_class ||= begin
        app = self
        Class.new(ActiveModelExtensions::Attachment).class_eval do
          include app.analyser.analysis_methods
          include app.job_definitions
          self
        end
      end
    end

    def store(object, opts={})
      temp_object = object.is_a?(TempObject) ? object : TempObject.new(object)
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

    def define_remote_url(&block)
      self.get_remote_url = proc(&block)
    end
    configuration_method :define_remote_url
    
    def remote_url_for(uid, *args)
      raise NotImplementedError, "You need to configure remote_urls on the Dragonfly app" if get_remote_url.nil?
      get_remote_url.call(uid, *args)
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

    attr_accessor :get_remote_url

    def saved_configs
      self.class.saved_configs
    end

    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
