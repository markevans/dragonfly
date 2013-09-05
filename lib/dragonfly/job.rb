require 'forwardable'
require 'digest/sha1'
require 'uri'
require 'open-uri'
require 'pathname'
require 'dragonfly/serializer'
require 'dragonfly/content'
require 'dragonfly/url_attributes'
require 'dragonfly/job_endpoint'

module Dragonfly
  class Job

    # Exceptions
    class AppDoesNotMatch < StandardError; end
    class JobAlreadyApplied < StandardError; end
    class NothingToProcess < StandardError; end
    class InvalidArray < StandardError; end
    class NoSHAGiven < StandardError; end
    class IncorrectSHA < StandardError; end

    extend Forwardable
    def_delegators :result,
                   :data, :file, :tempfile, :path, :to_file, :size, :each,
                   :meta, :meta=, :add_meta, :name, :name=, :basename, :basename=, :ext, :ext=, :mime_type,
                   :analyse, :store,
                   :b64_data

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
        # Dragonfly::Job::Fetch -> 'f'
        def abbreviation
          @abbreviation ||= basename.scan(/[A-Z]/).join.downcase
        end
      end

      def initialize(job, *args)
        @job, @args = job, args
        init
      end

      def init # To be overridden
      end

      attr_reader :job, :args

      def app
        job.app
      end

      def to_a
        [self.class.abbreviation, *args]
      end

      def inspect
        "#{self.class.step_name}(#{args.map{|a| a.inspect }.join(', ')})"
      end

    end

    class Fetch < Step
      def uid
        args.first
      end

      def apply
        app.datastore.retrieve(job.content, uid)
      end
    end

    class Process < Step
      def init
        processor.update_url(job.url_attrs, *arguments) if processor.respond_to?(:update_url)
      end

      def name
        args.first.to_sym
      end

      def arguments
        args[1..-1]
      end

      def processor
        @processor ||= app.get_processor(name)
      end

      def apply
        processor.call(job.content, *arguments)
      end
    end

    class Generate < Step
      def init
        generator.update_url(job.url_attrs, *arguments) if generator.respond_to?(:update_url)
      end

      def name
        args.first
      end

      def generator
        @generator ||= app.get_generator(name)
      end

      def arguments
        args[1..-1]
      end

      def apply
        generator.call(job.content, *arguments)
      end
    end

    class FetchFile < Step
      def initialize(job, path)
        super(job, path.to_s)
      end
      def init
        job.url_attrs.name = filename
      end

      def path
        @path ||= File.expand_path(args.first)
      end

      def filename
        @filename ||= File.basename(path)
      end

      def apply
        job.content.update(Pathname.new(path), 'name' => filename)
      end
    end

    class FetchUrl < Step
      class ErrorResponse < RuntimeError
        def initialize(status, body)
          @status, @body = status, body
        end
        attr_reader :status, :body
      end

      def init
        job.url_attrs.name = filename
      end

      def url
        @url ||= URI.escape((args.first[%r<^\w+://>] ? args.first : "http://#{args.first}"))
      end

      def path
        @path ||= URI.parse(url).path
      end

      def filename
        @filename ||= File.basename(path) if path[/[^\/]$/]
      end

      def apply
        begin
          open(url) do |f|
            job.content.update(f.read, 'name' => filename)
          end
        rescue OpenURI::HTTPError => e
          status, message = e.io.status
          raise ErrorResponse.new(status.to_i, e.io.read)
        end
      end
    end

    STEPS = [
      Fetch,
      Process,
      Generate,
      FetchFile,
      FetchUrl
    ]

    # Class methods
    class << self

      def from_a(steps_array, app)
        unless steps_array.is_a?(Array) &&
               steps_array.all?{|s| s.is_a?(Array) && step_abbreviations[s.first.to_s] }
          raise InvalidArray, "can't define a job from #{steps_array.inspect}"
        end
        job = app.new_job
        steps_array.each do |step_array|
          step_class = step_abbreviations[step_array.shift.to_s]
          job.steps << step_class.new(job, *step_array)
        end
        job
      end

      def deserialize(string, app)
        array = begin
          Serializer.json_b64_decode(string)
        rescue Serializer::BadString
          if app.allow_legacy_urls
            Serializer.marshal_b64_decode(string, :check_malicious => true) # legacy strings
          else
            raise
          end
        end
        from_a(array, app)
      end

      def step_abbreviations
        @step_abbreviations ||= STEPS.inject({}){|hash, step_class| hash[step_class.abbreviation] = step_class; hash }
      end

      def step_names
        @step_names ||= STEPS.map{|step_class| step_class.step_name }
      end

    end

    def initialize(app, content="", meta={})
      @app = app
      @next_step_index = 0
      @steps = []
      @content = Content.new(app, content, meta)
      @url_attrs = UrlAttributes.new
    end

    # Used by 'dup' and 'clone'
    def initialize_copy(other)
      @steps = other.steps.map do |step|
        step.class.new(self, *step.args)
      end
      @content = other.content.dup
      @url_attrs = other.url_attrs.dup
    end

    attr_reader :app, :steps, :content

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

    # Applying, etc.

    def apply
      pending_steps.each{|step| step.apply }
      self.next_step_index = steps.length
      self
    end

    def applied?
      next_step_index == steps.length
    end

    def applied_steps
      steps[0...next_step_index]
    end

    def pending_steps
      steps[next_step_index..-1]
    end

    def to_a
      steps.map{|step| step.to_a }
    end

    # Serializing, etc.

    def to_unique_s
      to_a.to_dragonfly_unique_s
    end

    def serialize
      Serializer.json_b64_encode(to_a)
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
      app.url_for(self, opts) unless steps.empty?
    end

    attr_reader :url_attrs

    def update_url_attrs(hash)
      hash.each do |key, value|
        url_attrs.send("#{key}=", value)
      end
    end

    # to_stuff...

    def to_app
      JobEndpoint.new(self)
    end

    def to_response(env={"REQUEST_METHOD" => "GET"})
      to_app.call(env)
    end

    def to_fetched_job(uid)
      new_job = dup
      new_job.steps = []
      new_job.fetch!(uid)
      new_job.next_step_index = 1
      new_job
    end

    # Step inspection

    def uid
      step = fetch_step
      step.uid if step
    end

    def fetch_step
      last_step_of_type(Fetch)
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

    def step_types
      steps.map{|s| s.class.step_name }
    end

    # Misc

    def inspect
      "<Dragonfly::Job app=#{app.name.inspect}, steps=#{steps.inspect}, content=#{content.inspect}, steps applied:#{applied_steps.length}/#{steps.length} >"
    end

    protected

    attr_writer :steps
    attr_accessor :next_step_index

    private

    def result
      apply
      content
    end

    def last_step_of_type(type)
      steps.select{|s| s.is_a?(type) }.last
    end

  end
end
