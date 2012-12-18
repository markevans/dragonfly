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

      def apps
        @apps ||= {}
      end

      def default_app
        instance(:default)
      end

      def destroy_apps
        apps.clear
      end

    end

    def initialize(name)
      @name = name
      @analyser, @processor, @generator = Analyser.new, Processor.new, Generator.new
      @server = Server.new(self)
      @content_filename = Dragonfly::Response::DEFAULT_FILENAME
    end

    attr_reader :name

    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch, :generate, :fetch_file, :fetch_url
    def_delegators :server, :call

    extend Configurable
    setup_config do
      # Exceptions (these come under App namespace)
      class UnregisteredDataStore < RuntimeError; end

      writer :cache_duration, :secret, :log, :content_disposition, :content_filename
      meth :register_mime_type, :response_headers, :define_url, :add_processor, :build_processor, :add_generator

      def datastore(store, *args)
        obj.datastore = if store.is_a?(Symbol)
          get_klass = _datastores[store]
          raise UnregisteredDataStore, "the datastore '#{store}' is not registered" unless get_klass
          klass = get_klass.call
          klass.new(*args)
        else
          raise ArgumentError, "datastore only takes 1 argument unless you use a symbol" if args.any?
          store
        end
      end

      writer :allow_fetch_file, :allow_fetch_url, :dragonfly_url, :protect_from_dos_attacks, :url_format, :url_host,
             :for => :server
      meth :before_serve, :for => :server

      def analyser_cache_size(value)
        obj.analyser.cache_size = value
      end

      def register_datastore(symbol, &block) # For use publicly, not in a config block
        _datastores[symbol] = block
      end

      # "private"
      def _datastores
        @_datastores ||= {}
      end
    end

    attr_reader :analyser
    attr_reader :processor
    attr_reader :generator
    attr_reader :server

    def datastore
      @datastore ||= DataStorage::FileDataStore.new
    end
    attr_writer :datastore

    def add_generator(*args, &block)
      generator.add(*args, &block)
    end

    def add_processor(*args, &block)
      processor.add(*args, &block)
    end

    def build_processor(*args, &block)
      processor.build(*args, &block)
    end

    def new_job(content=nil, meta={})
      job_class.new(self, content, meta)
    end
    alias create new_job

    def endpoint(job=nil, &block)
      block ? RoutedEndpoint.new(self, &block) : JobEndpoint.new(job)
    end

    def job_class
      @job_class ||= begin
        app = self
        Class.new(Job).class_eval do
          include app.analyser.analysis_methods
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

    def registered_mime_types
      @registered_mime_types ||= Rack::Mime::MIME_TYPES.dup
    end

    def mime_type_for(format)
      registered_mime_types[file_ext_string(format)]
    end

    def response_headers
      @response_headers ||= {}
    end

    def define_url(&block)
      @url_proc = block
    end

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

    # Reflection
    def processor_methods
      processor.names
    end

    def generator_methods
      generator.names
    end

    def analyser_methods
      analyser.analysis_method_names
    end

    def inspect
      "<#{self.class.name} name=#{name.inspect} >"
    end

    def fallback_mime_type
      'application/octet-stream'
    end

    def cache_duration
      @cache_duration ||= 3600*24*365 # (1 year)
    end
    attr_writer :cache_duration

    def secret
      @secret ||= 'secret yo'
    end
    attr_writer :secret

    def log
      @log ||= Logger.new('/var/tmp/dragonfly.log')
    end
    attr_writer :log

    attr_accessor :content_disposition, :content_filename

    private

    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
