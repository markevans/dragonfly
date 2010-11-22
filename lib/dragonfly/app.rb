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
      @job_definitions = JobDefinitions.new
      @server = Dragonfly::SimpleEndpoint.new(self)
    end

    include Configurable

    extend Forwardable
    def_delegator :datastore, :destroy
    def_delegators :new_job, :fetch, :generate, :fetch_file
    def_delegator :server, :call

    configurable_attr :datastore do DataStorage::FileDataStore.new end
    configurable_attr :cache_duration, 3600*24*365 # (1 year)
    configurable_attr :fallback_mime_type, 'application/octet-stream'
    configurable_attr :url_path_prefix
    configurable_attr :url_host
    configurable_attr :url_suffix
    configurable_attr :protect_from_dos_attacks, false
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

    SAVED_CONFIGS = {
      :imagemagick => 'ImageMagick',
      :image_magick => 'ImageMagick',
      :rmagick => 'RMagick',
      :r_magick => 'RMagick',
      :rails => 'Rails',
      :heroku => 'Heroku'
    }

    def configurer_for(symbol)
      class_name = SAVED_CONFIGS[symbol]
      if class_name.nil?
        raise ArgumentError, "#{symbol.inspect} is not a known configuration - try one of #{SAVED_CONFIGS.keys.join(', ')}"
      end
      Config.const_get(class_name)
    end

    def new_job(content=nil, opts={})
      content ? Job.new(self, TempObject.new(content, opts)) : Job.new(self)
    end

    def endpoint(job=nil, &block)
      block ? RoutedEndpoint.new(self, &block) : JobEndpoint.new(job)
    end

    def job(name, &block)
      job_definitions.add(name, &block)
    end
    configuration_method :job

    def store(object, opts={})
      temp_object = object.is_a?(TempObject) ? object : TempObject.new(object)
      temp_object.extract_attributes_from(opts)
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

    def resolve_mime_type(temp_object)
      mime_type_for(temp_object.format)                                   ||
        (mime_type_for(temp_object.ext) if infer_mime_type_from_file_ext) ||
        analyser.analyse(temp_object, :mime_type)                         ||
        mime_type_for(analyser.analyse(temp_object, :format))             ||
        fallback_mime_type
    end

    def mount_path
      url_path_prefix.blank? ? '/' : url_path_prefix
    end

    def url_for(job, *args)
      if (args.length == 1 && args.first.kind_of?(Hash)) || args.empty?
        opts = args.first ? args.first.dup : {}
        host = opts.delete(:host) || url_host
        suffix = opts.delete(:suffix) || url_suffix
        suffix = suffix.call(job) if suffix.respond_to?(:call)
        path_prefix = opts.delete(:path_prefix) || url_path_prefix
        path = "#{host}#{path_prefix}#{job.to_path}#{suffix}"
        server.prepare_path_for(path, job) if protect_from_dos_attacks
        query = opts
        path << "?#{Rack::Utils.build_query(query)}" if query.any?
        path
      else
        # Deprecation stuff - will be removed!!!
        case args[0]
        when /^(\d+)?x(\d+)?/
          log.warn("DEPRECATED USE OF url_for and will be removed in the future - please use thumb(#{args.map{|a|a.inspect}.join(', ')}).url")
          args[1] ? job.thumb(args[0], args[1]).url : job.thumb(args[0]).url
        when :gif, :png, :jpg, :jpeg
          log.warn("DEPRECATED USE OF url_for and will be removed in the future - please use encode(#{args.first.inspect}).url")
          job.encode(args[0]).url
        else
          raise "DEPRECATED USE OF url_for - will be removed in future versions - please consult the docs"
        end
      end
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
