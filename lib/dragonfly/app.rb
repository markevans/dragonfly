require 'forwardable'
require 'rack'
require 'dragonfly/register'
require 'dragonfly/server'
require 'dragonfly/shell'
require 'dragonfly/configurable'
require 'dragonfly/file_data_store'
require 'dragonfly/routed_endpoint'
require 'dragonfly/job_endpoint'
require 'dragonfly/job'

module Dragonfly
  class App

    # Exceptions
    class UnregisteredDataStore < RuntimeError; end

    DEFAULT_NAME = :default

    class << self
      extend Forwardable
      def_delegator :configurer, :register_plugin

      private :new # Hide 'new' - need to use 'instance'

      def instance(name=nil)
        name ||= DEFAULT_NAME
        name = name.to_sym
        apps[name] ||= new(name)
      end

      def [](name)
        raise "Dragonfly::App[#{name.inspect}] is deprecated - use Dragonfly.app (for the default app) or Dragonfly.app(#{name.inspect}) (for extra named apps) instead. See docs at http://markevans.github.io/dragonfly for details"
      end

      def apps
        @apps ||= {}
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
      @job_methods = Module.new
      @shell = Shell.new
      @env = {}
    end

    attr_reader :name, :env

    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch, :generate, :fetch_file, :fetch_url
    def_delegators :server, :call, :fetch_file_whitelist, :fetch_url_whitelist

    # Configuration

    extend Configurable

    set_up_config do
      writer :secret, :allow_legacy_urls
      meth :response_header, :define_url, :define

      def processor(*args, &block)
        obj.add_processor(*args, &block)
      end

      def generator(*args, &block)
        obj.add_generator(*args, &block)
      end

      def analyser(*args, &block)
        obj.add_analyser(*args, &block)
      end

      def datastore(*args)
        obj.use_datastore(*args)
      end

      def mime_type(*args)
        obj.add_mime_type(*args)
      end

      def fetch_file_whitelist(patterns)
        obj.server.add_to_fetch_file_whitelist(patterns)
      end

      def fetch_url_whitelist(patterns)
        obj.server.add_to_fetch_url_whitelist(patterns)
      end

      writer :dragonfly_url, :verify_urls, :url_format, :url_host, :url_path_prefix,
             :for => :server
      meth :before_serve, :for => :server

      def protect_from_dos_attacks(boolean)
        verify_urls(boolean)
        Dragonfly.warn("configuration option protect_from_dos_attacks is deprecated - use verify_urls instead")
      end

      def method_missing(meth, *args)
        raise NoMethodError, "no method '#{meth}' for App configuration - but the configuration API has changed! see docs at http://markevans.github.io/dragonfly for details"
      end
    end

    attr_reader :analysers
    attr_reader :processors
    attr_reader :generators
    attr_reader :server

    def datastore
      @datastore ||= FileDataStore.new
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
      raise "datastores have a new interface (read/write/destroy) - see docs at http://markevans.github.io/dragonfly for details" if datastore.respond_to?(:store) && !datastore.respond_to?(:write)
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

    def ext_for(mime_type)
      return 'txt' if mime_type == 'text/plain'
      ext = key_for(mime_types, mime_type)
      ext.tr('.', '') if ext
    end

    def response_header(key, value=nil, &block)
      response_headers[key] = value || block
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
    rescue NoMethodError
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

    attr_accessor :allow_legacy_urls, :secret

    def define_macro(klass, name)
      raise NoMethodError, "define_macro is deprecated - instead of defining #{name}, just extend #{klass.name} with Dragonfly::Model and use dragonfly_accessor"
    end

    def define_macro_on_include(mod, name)
      raise NoMethodError, "define_macro_on_include is deprecated - instead of defining #{name}, just extend the relevant class with Dragonfly::Model and use dragonfly_accessor"
    end

    private

    def file_ext_string(format)
      '.' + format.to_s.downcase.sub(/^.*\./,'')
    end

    def key_for(hash, value)
      if hash.respond_to?(:key)
        hash.key(value)
      else
        hash.each {|k, v| return k if v == value }
        nil
      end
    end

  end
end
