require 'forwardable'
require 'digest/sha1'
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
    class CannotGenerateSha < StandardError; end

    extend Forwardable
    def_delegators :result,
                   :data, :file, :tempfile, :path, :to_file, :size, :each,
                   :meta, :meta=, :add_meta, :name, :name=, :basename, :basename=, :ext, :ext=, :mime_type,
                   :analyse, :shell_eval, :store,
                   :b64_data,
                   :close

    require 'dragonfly/job/fetch'
    require 'dragonfly/job/fetch_file'
    require 'dragonfly/job/fetch_url'
    require 'dragonfly/job/generate'
    require 'dragonfly/job/process'

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
            Serializer.marshal_b64_decode(string) # legacy strings
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
      @url_attributes = UrlAttributes.new
    end

    # Used by 'dup' and 'clone'
    def initialize_copy(other)
      @steps = other.steps.map do |step|
        step.class.new(self, *step.args)
      end
      @content = other.content.dup
      @url_attributes = other.url_attributes.dup
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

    def signature
      Digest::SHA1.hexdigest(to_unique_s)
    end

    def sha
      unless app.secret
        raise CannotGenerateSha, "A secret is required to sign and verify Dragonfly job requests. "\
                                 "Use `secret '...'` or `verify_urls false` (not recommended!) in your config."
      end
      OpenSSL::HMAC.hexdigest('SHA256', app.secret, to_unique_s)[0,16]
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

    attr_reader :url_attributes

    def update_url_attributes(hash)
      hash.each do |key, value|
        url_attributes.send("#{key}=", value)
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
