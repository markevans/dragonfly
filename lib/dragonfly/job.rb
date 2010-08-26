require 'forwardable'
require 'digest/sha1'

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
    def_delegators :result, :data, :file, :tempfile, :path, :to_file, :size, :ext, :name, :meta, :format, :_format

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

      def initialize(*args)
        @args = args
      end
      attr_reader :args
      def inspect
        "#{self.class.step_name}(#{args.map{|a| a.inspect }.join(', ')})"
      end
    end

    class Fetch < Step
      def uid
        args.first
      end
      def apply(job)
        content, extra = job.app.datastore.retrieve(uid)
        job.temp_object = TempObject.new(content, (extra || {}))
      end
    end

    class Process < Step
      def name
        args.first
      end
      def arguments
        args[1..-1]
      end
      def apply(job)
        raise NothingToProcess, "Can't process because temp object has not been initialized. Need to fetch first?" unless job.temp_object
        old = job.temp_object
        job.temp_object = TempObject.new(
          job.app.processor.process(old, name, *arguments),
          old.attributes
        )
      end
    end

    class Encode < Step
      def format
        args.first
      end
      def arguments
        args[1..-1]
      end
      def apply(job)
        raise NothingToEncode, "Can't encode because temp object has not been initialized. Need to fetch first?" unless job.temp_object
        old = job.temp_object
        job.temp_object = TempObject.new(
          job.app.encoder.encode(old, format, *arguments),
          old.attributes.merge(:format => format)
        )
      end
    end

    class Generate < Step
      def apply(job)
        content, extra = job.app.generator.generate(*args)
        job.temp_object = TempObject.new(content, (extra || {}))
      end
    end

    class FetchFile < Step
      def path
        File.expand_path(args.first)
      end
      def apply(job)
        job.temp_object = TempObject.new(File.new(path))
      end
    end

    STEPS = [
      Fetch,
      Process,
      Encode,
      Generate,
      FetchFile
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
          job.steps << step_class.new(*step_array)
        end
        job
      end

      def from_path(path, app)
        path = path.dup
        path.sub!(app.url_path_prefix, '') if app.url_path_prefix
        path.sub!('/', '')
        deserialize(path, app)
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

    # Instance methods

    def initialize(app, temp_object=nil)
      @app = app
      self.extend app.analyser.analysis_methods
      self.extend app.job_definitions
      @steps = []
      @next_step_index = 0
      @temp_object = temp_object
    end

    # Used by 'dup' and 'clone'
    def initialize_copy(other)
      self.steps = other.steps.dup
      self.extend app.analyser.analysis_methods
      self.extend app.job_definitions
    end

    attr_accessor :temp_object
    attr_reader :app, :steps

    # define fetch(), fetch!(), process(), etc.
    STEPS.each do |step_class|
      class_eval %(
        def #{step_class.step_name}(*args)
          new_job = self.dup
          new_job.steps << #{step_class}.new(*args)
          new_job
        end

        def #{step_class.step_name}!(*args)
          steps << #{step_class}.new(*args)
          self
        end
      )
    end

    def analyse(method, *args)
      unless result
        raise NothingToAnalyse, "Can't analyse because temp object has not been initialized. Need to fetch first?"
      end
      # Hacky - wish there was a nicer way to do this without extending with yet another module
      if method == :format
        _format || analyser.analyse(result, method, *args)
      else
        analyser.analyse(result, method, *args)
      end
    end

    def +(other_job)
      unless app == other_job.app
        raise AppDoesNotMatch, "Cannot add jobs belonging to different apps (#{app} is not #{other_job.app})"
      end
      unless other_job.applied_steps.empty?
        raise JobAlreadyApplied, "Cannot add jobs when the second one has already been applied (#{other_job})"
      end
      new_job = self.class.new(app, temp_object)
      new_job.steps = steps + other_job.steps
      new_job.next_step_index = next_step_index
      new_job
    end

    def apply
      pending_steps.each{|step| step.apply(self) }
      self.next_step_index = steps.length
      self
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

    def serialize
      Serializer.marshal_encode(to_a)
    end

    def unique_signature
      Digest::SHA1.hexdigest(serialize)
    end

    def sha
      Digest::SHA1.hexdigest("#{serialize}#{app.secret}")[0...8]
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

    def to_app
      JobEndpoint.new(self)
    end

    def to_response(env={})
      to_app.call(env)
    end

    def url(*args)
      app.url_for(self, *args) unless steps.empty?
    end

    def to_fetched_job(uid)
      new_job = self.class.new(app, temp_object)
      new_job.fetch!(uid)
      new_job.next_step_index = 1
      new_job
    end

    def to_path
      "/#{serialize}"
    end

    def inspect
      to_s.sub(/>$/, " app=#{app}, steps=#{steps.inspect}, temp_object=#{temp_object.inspect}, steps applied:#{applied_steps.length}/#{steps.length} >")
    end

    protected

    attr_writer :steps
    attr_accessor :next_step_index

  end
end
