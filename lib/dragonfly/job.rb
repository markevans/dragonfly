require 'forwardable'

module Dragonfly
  class Job

    # Exceptions
    class AppDoesNotMatch < StandardError; end
    class NothingToProcess < StandardError; end
    class NothingToEncode < StandardError; end
    class NothingToAnalyse < StandardError; end
    
    include BelongsToApp
    
    extend Forwardable
    def_delegators :resulting_temp_object, :data
    
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
        job.temp_object = TempObject.new job.app.datastore.retrieve(uid)
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
    
    class Encoding < Step
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
    
    def initialize(app, &block)
      @app = app
      @steps = []
      @next_step_index = 0
    end
    
    attr_accessor :temp_object
    attr_reader :steps

    def fetch(uid)
      steps << Fetch.new(uid)
      self
    end

    def process(*args)
      steps << Process.new(*args)
      self
    end
    
    def encode(*args)
      steps << Encoding.new(*args)
      self
    end
    
    def analyse(*args)
      raise NothingToAnalyse, "Can't analyse because temp object has not been initialized. Need to fetch first?" unless temp_object
      app.analysers.analyse(resulting_temp_object, *args)
    end

    def +(other_job)
      unless app == other_job.app
        raise AppDoesNotMatch, "Cannot add jobs belonging to different apps (#{app} is not #{other_job.app})"
      end
      new_job = self.class.new(app)
      new_job.steps = steps + other_job.steps
      new_job
    end
    
    def apply
      pending_steps.each{|step| step.apply(self) }
      self.next_step_index = steps.length
    end
    
    def applied_steps
      steps[0...next_step_index]
    end
    
    def pending_steps
      steps[next_step_index..-1]
    end

    protected
    attr_writer :steps

    private
    
    attr_accessor :next_step_index
    
    def resulting_temp_object
      apply
      temp_object
    end

  end
end