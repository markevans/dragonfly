require 'forwardable'
require 'digest/sha1'
require 'base64'
require 'open-uri'
require 'pathname'

module Dragonfly
  class Job

    # Exceptions
    class AppDoesNotMatch < StandardError; end
    class JobAlreadyApplied < StandardError; end
    class NothingToProcess < StandardError; end
    class NothingToEncode < StandardError; end
    class NothingToAnalyse < StandardError; end
    class InvalidArray < StandardError; end
    class NoSHAGiven < StandardError; end
    class IncorrectSHA < StandardError; end

    extend Forwardable
    def_delegators :result,
                   :data, :file, :tempfile, :path, :to_file, :size

    class Step

      class << self
        # Dragonfly::Job::Fetch -> 'Fetch'
        def basename
          @basename ||= name.split('::').last
        end
        # Dragonfly::Job::Fetch -> :fetch
        def step_name
          @step_name ||= basename.gsub(/[A-Z]/){ "_#{$&.downcase}" }.sub('_','').to_sym
        end
        # Dragonfly::Job::Fetch -> :f
        def abbreviation
          @abbreviation ||= basename.scan(/[A-Z]/).join.downcase.to_sym
        end
      end

      def initialize(job, *args)
        @job, @args = job, args
        init
      end

      def init # To be overridden
      end

      attr_reader :job, :args

      def inspect
        "#{self.class.step_name}(#{args.map{|a| a.inspect }.join(', ')})"
      end

      private
      
      def update_job(content, meta)
        job.temp_object = TempObject.new(content)
        job.meta.merge!(meta) if meta
      end

    end

    class Fetch < Step
      def uid
        args.first
      end
      def apply
        content, meta = job.app.datastore.retrieve(uid)
        update_job(content, meta)
      end
    end

    class Process < Step
      def name
        args.first
      end
      def arguments
        args[1..-1]
      end
      def apply
        raise NothingToProcess, "Can't process because temp object has not been initialized. Need to fetch first?" unless job.temp_object
        content, meta = job.app.processor.process(job.temp_object, name, *arguments)
        update_job(content, meta)
      end
    end

    class Encode < Step
      def init
        job.meta[:format] = format
      end
      def format
        args.first
      end
      def arguments
        args[1..-1]
      end
      def apply
        raise NothingToEncode, "Can't encode because temp object has not been initialized. Need to fetch first?" unless job.temp_object
        content, meta = job.app.encoder.encode(job.temp_object, format, *arguments)
        update_job(content, meta)
        job.meta[:format] = format
      end
    end

    class Generate < Step
      def apply
        content, meta = job.app.generator.generate(*args)
        update_job(content, meta)
      end
    end

    class FetchFile < Step
      def init
        job.name = File.basename(path)
      end
      def path
        File.expand_path(args.first)
      end
      def apply
        job.temp_object = TempObject.new(Pathname.new(path))
      end
    end

    class FetchUrl < Step
      def init
        job.name = File.basename(path) if path[/[^\/]$/]
      end
      def url
        @url ||= (args.first[%r<^\w+://>] ? args.first : "http://#{args.first}")
      end
      def path
        @path ||= URI.parse(url).path
      end
      def apply
        open(url) do |f|
          job.temp_object = TempObject.new(f.read)
        end
      end
    end

    STEPS = [
      Fetch,
      Process,
      Encode,
      Generate,
      FetchFile,
      FetchUrl
    ]

    # Class methods
    class << self

      def from_a(steps_array, app)
        unless steps_array.is_a?(Array) &&
               steps_array.all?{|s| s.is_a?(Array) && step_abbreviations[s.first] }
          raise InvalidArray, "can't define a job from #{steps_array.inspect}"
        end
        job = app.new_job
        steps_array.each do |step_array|
          step_class = step_abbreviations[step_array.shift]
          job.steps << step_class.new(job, *step_array)
        end
        job
      end

      def deserialize(string, app)
        from_a(Serializer.marshal_decode(string), app)
      end

      def step_abbreviations
        @step_abbreviations ||= STEPS.inject({}){|hash, step_class| hash[step_class.abbreviation] = step_class; hash }
      end

      def step_names
        @step_names ||= STEPS.map{|step_class| step_class.step_name }
      end

    end

    ####### Instance methods #######

    # This is needed because we need a way of overriding
    # the methods added to Job objects by the analyser and by
    # the job shortcuts like 'thumb', etc.
    # If we had traits/classboxes in ruby maybe this wouldn't be needed
    # Think of it as like a normal instance method but with a css-like !important after it
    module OverrideInstanceMethods
      
      def format
        apply
        meta[:format] || (ext.to_sym if ext && app.infer_mime_type_from_file_ext) || analyse(:format)
      end
      
      def mime_type
        app.mime_type_for(format) || analyse(:mime_type) || app.fallback_mime_type
      end
      
      def to_s
        super.sub(/#<Class:\w+>/, 'Extended Dragonfly::Job')
      end
      
    end

    def initialize(app, temp_object=nil, meta={})
      @app = app
      @steps = []
      @next_step_index = 0
      @temp_object = temp_object
      self.meta = meta
    end

    # Used by 'dup' and 'clone'
    def initialize_copy(other)
      self.steps = other.steps.map do |step|
        step.class.new(self, *step.args)
      end
    end

    attr_accessor :temp_object
    attr_reader :app, :steps

    # define fetch(), fetch!(), process(), etc.
    STEPS.each do |step_class|
      class_eval %(
        def #{step_class.step_name}(*args)
          new_job = self.dup
          new_job.steps << #{step_class}.new(new_job, *args)
          new_job
        end

        def #{step_class.step_name}!(*args)
          steps << #{step_class}.new(self, *args)
          self
        end
      )
    end

    def analyse(method, *args)
      unless result
        raise NothingToAnalyse, "Can't analyse because temp object has not been initialized. Need to fetch first?"
      end
      analyser.analyse(result, method, *args)
    end

    # Applying, etc.

    def apply
      pending_steps.each{|step| step.apply }
      self.next_step_index = steps.length
      self
    end

    def applied?
      next_step_index == steps.length
    end

    def result
      apply
      temp_object
    end

    def applied_steps
      steps[0...next_step_index]
    end

    def pending_steps
      steps[next_step_index..-1]
    end

    def to_a
      steps.map{|step|
        [step.class.abbreviation, *step.args]
      }
    end

    # Serializing, etc.

    def to_unique_s
      to_a.to_dragonfly_unique_s
    end

    def serialize
      Serializer.marshal_encode(to_a)
    end

    def unique_signature
      Digest::SHA1.hexdigest(to_unique_s)
    end

    def sha
      Digest::SHA1.hexdigest("#{to_unique_s}#{app.secret}")[0...8]
    end

    def validate_sha!(sha)
      case sha
      when nil
        raise NoSHAGiven
      when self.sha
        self
      else
        raise IncorrectSHA, sha
      end
    end

    # URLs, etc.

    def url(opts={})
      app.server.url_for(self, attributes_for_url.merge(opts)) unless steps.empty?
    end

    def b64_data
      "data:#{mime_type};base64,#{Base64.encode64(data)}"
    end

    # to_stuff...

    def to_app
      JobEndpoint.new(self)
    end

    def to_response(env={})
      to_app.call(env)
    end

    def to_path
      "/#{serialize}"
    end

    def to_fetched_job(uid)
      new_job = self.class.new(app, temp_object)
      new_job.fetch!(uid)
      new_job.next_step_index = 1
      new_job
    end

    # Step inspection

    def fetch_step
      last_step_of_type(Fetch)
    end

    def uid
      step = fetch_step
      step.uid if step
    end

    def uid_basename
      File.basename(uid, '.*') if uid
    end

    def uid_extname
      File.extname(uid) if uid
    end

    def generate_step
      last_step_of_type(Generate)
    end

    def fetch_file_step
      last_step_of_type(FetchFile)
    end

    def fetch_url_step
      last_step_of_type(FetchUrl)
    end

    def process_steps
      steps.select{|s| s.is_a?(Process) }
    end

    def encode_step
      last_step_of_type(Encode)
    end

    def encoded_format
      step = encode_step
      step.format if step
    end

    def encoded_extname
      format = encoded_format
      ".#{format}" if format
    end

    # Misc

    def store(opts={})
      app.store(result, opts)
    end

    def inspect
      to_s.sub(/>$/, " app=#{app}, steps=#{steps.inspect}, temp_object=#{temp_object.inspect}, steps applied:#{applied_steps.length}/#{steps.length} >")
    end

    # Name and stuff
        
    attr_reader :meta

    def meta=(hash)
      raise ArgumentError, "meta must be a hash, you tried setting it as #{hash.inspect}" unless hash.is_a?(Hash)
      @meta = hash
    end

    def name
      meta[:name]
    end

    def name=(name)
      meta[:name] = name
    end
    
    def basename
      File.basename(name, '.*') if name
    end

    def ext
      File.extname(name)[/\.(.*)/, 1] if name
    end

    def attributes_for_url
      meta.reject{|k, v| !app.server.params_in_url.include?(k.to_s) }
    end
    
    protected

    attr_writer :steps
    attr_accessor :next_step_index

    private

    def last_step_of_type(type)
      steps.select{|s| s.is_a?(type) }.last
    end

  end
end
