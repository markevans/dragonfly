require 'forwardable'

module Dragonfly
  class Job

    # Exceptions
    class AppDoesNotMatch < StandardError; end
    class JobAlreadyApplied < StandardError; end
    class NothingToProcess < StandardError; end
    class NothingToEncode < StandardError; end
    class NothingToAnalyse < StandardError; end
    class InvalidArray < StandardError; end
    
    include BelongsToApp
    
    extend Forwardable
    def_delegators :apply, :data
    def_delegators :steps, :any?, :empty?
    
    class Step
      def initialize(*args)
        @args = args
      end
      attr_reader :args
    end

    class Fetch < Step
      def uid
        args.first
      end
      def apply(job)
        job.temp_object = TempObject.new(*job.app.datastore.retrieve(uid))
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
        job.temp_object = TempObject.new job.app.processors.process(job.temp_object, name, *arguments)
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
        job.temp_object = TempObject.new job.app.encoders.encode(job.temp_object, format, *arguments)
      end
    end
    
    STEP_ABBREVIATIONS = {
      Fetch   => :f,
      Process => :p,
      Encode  => :e
    }
    
    # Class methods
    class << self
      
      def from_a(steps_array, app)
        unless steps_array.is_a?(Array) &&
               steps_array.all?{|s| s.is_a?(Array) && STEP_ABBREVIATIONS.index(s.first) }
          raise InvalidArray, "can't define a job from #{steps_array.inspect}"
        end
        job = Job.new(app)
        steps_array.each do |step_array|
          step_class = STEP_ABBREVIATIONS.index(step_array.shift)
          job.steps << step_class.new(*step_array)
        end
        job
      end
      
      def deserialize(string, app)
        from_a(Serializer.marshal_decode(string), app)
      end
      
    end

    # Instance methods

    def initialize(app, content=nil)
      @app = app
      @steps = []
      @next_step_index = 0
      @temp_object = TempObject.new(content) if content
    end
    
    attr_accessor :temp_object
    attr_reader :steps

    def fetch(*args)
      steps << Fetch.new(*args)
      self
    end

    def process(*args)
      steps << Process.new(*args)
      self
    end
    
    def encode(*args)
      steps << Encode.new(*args)
      self
    end
    
    def analyse(*args)
      raise NothingToAnalyse, "Can't analyse because temp object has not been initialized. Need to fetch first?" unless temp_object
      app.analysers.analyse(apply, *args)
    rescue Delegator::UnableToHandle => e
      log.warn(e.message)
      nil
    end

    def format
      encoding_steps.last.format if encoding_steps.any?
    end

    def mime_type
      app.mime_type_for(format) if format
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
        [STEP_ABBREVIATIONS[step.class], *step.args]
      }
    end

    def serialize
      Serializer.marshal_encode(to_a)
    end

    def to_app
      SimpleEndpoint.new(self)
    end
    
    def to_response
      to_app.call
    end

    def url
      app.url_for(self)
    end

    protected

    attr_writer :steps
    attr_accessor :next_step_index

    private
    
    def encoding_steps
      steps.select{|step| step.is_a?(Encode) }
    end

  end
end
