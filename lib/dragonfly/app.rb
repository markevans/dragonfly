require 'logger'
require 'forwardable'
require 'rack'

module Dragonfly
  class App

    # Exceptions
    class UnregisteredDataStore < RuntimeError; end

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

      def register_datastore(symbol, &block)
        available_datastores[symbol] = block
      end

      def available_datastores
        @available_datastores ||= {}
      end

    end

    def initialize(name)
      @name = name
      @analysers, @processors, @generators = Register.new, Register.new, Register.new
      @server = Server.new(self)
      @content_filename = Dragonfly::Response::DEFAULT_FILENAME
      @job_methods = Module.new
      @shell = Shell.new
    end

    attr_reader :name

    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch, :generate, :fetch_file, :fetch_url
    def_delegators :server, :call

    # Configuration

    extend Configurable

    setup_config do
      writer :cache_duration, :secret, :log, :content_disposition, :content_filename, :allow_legacy_urls
      meth :add_mime_type, :response_headers, :define_url, :add_processor, :add_generator, :add_analyser

      def datastore(*args)
        obj.use_datastore(*args)
      end

      writer :fetch_file_whitelist, :fetch_url_whitelist, :dragonfly_url, :protect_from_dos_attacks, :url_format, :url_host, :url_path_prefix,
             :for => :server
      meth :before_serve, :for => :server
    end

    attr_reader :analysers
    attr_reader :processors
    attr_reader :generators
    attr_reader :server

    def datastore
      @datastore ||= DataStorage::FileDataStore.new
    end
    attr_writer :datastore

    def use_datastore(store, *args)
      self.datastore = if store.is_a?(Symbol)
        get_klass = self.class.available_datastores[store]
        raise UnregisteredDataStore, "the datastore '#{store}' is not registered" unless get_klass
        klass = get_klass.call
        klass.new(*args)
      else
        raise ArgumentError, "datastore only takes 1 argument unless you use a symbol" if args.any?
        store
      end
    end

    def add_generator(*args, &block)
      generators.add(*args, &block)
    end

    def get_generator(name)
      generators.get(name)
    end

    def add_processor(name, callable=nil, &block)
      processors.add(name, callable, &block)
      define(name){|*args| process(name, *args) }
      define("#{name}!"){|*args| process!(name, *args) }
    end

    def get_processor(name)
      processors.get(name)
    end

    def add_analyser(name, callable=nil, &block)
      analysers.add(name, callable, &block)
      define(name){ analyse(name) }
    end

    def get_analyser(name)
      analysers.get(name)
    end

    def new_job(content="", meta={})
      job_class.new(self, content, meta)
    end
    alias create new_job

    attr_reader :shell

    def endpoint(job=nil, &block)
      block ? RoutedEndpoint.new(self, &block) : JobEndpoint.new(job)
    end

    attr_reader :job_methods

    def job_class
      @job_class ||= begin
        app = self
        Class.new(Job).class_eval do
          include app.job_methods
          self
        end
      end
    end

    def define(method, &block)
      job_methods.send(:define_method, method, &block)
    end

    def store(object, meta={}, opts={})
      create(object, meta).store(opts)
    end

    def add_mime_type(format, mime_type)
      mime_types[file_ext_string(format)] = mime_type
    end

    def mime_types
      @mime_types ||= Rack::Mime::MIME_TYPES.dup
    end

    def mime_type_for(format)
      mime_types[file_ext_string(format)] || fallback_mime_type
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
      processors.names
    end

    def generator_methods
      generators.names
    end

    def analyser_methods
      analysers.names
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
      @log ||= Logger.new('dragonfly.log')
    end
    attr_writer :log

    attr_accessor :content_disposition, :content_filename

    def allow_legacy_urls
      @allow_legacy_urls = true if @allow_legacy_urls.nil?
      @allow_legacy_urls
    end
    attr_writer :allow_legacy_urls

    private

    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

  end
end
