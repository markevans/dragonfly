require 'forwardable'

module Dragonfly
  class Job
    
    extend Forwardable
    def_delegators :resulting_temp_object, :data
    
    class Step
      def initialize(*args)
        @args = args
      end
      private
      attr_reader :args
    end
    
    # Processing job part
    class Process < Step
      def name
        args.first
      end
      def arguments
        args[1..-1]
      end
      def apply(job)
        job.temp_object = TempObject.new job.app.processors.send(name, job.temp_object, *arguments)
      end
      def to_a
        [:process, *args]
      end
    end
    
    # Encoding job part
    class Encoding < Step
      def format
        args.first
      end
      def arguments
        args[1..-1]
      end
      def apply(job)
        job.temp_object = TempObject.new job.app.encoders.encode(job.temp_object, format, *arguments)
      end
      def to_a
        [:encoding, *args]
      end
    end
    
    def initialize(app, temp_object=nil, &block)
      @app = app
      @temp_object = temp_object
      @steps = []
      @next_step = 0
    end
    
    attr_accessor :temp_object
    attr_reader :steps, :app

    def process(*args)
      steps << Process.new(*args)
      self
    end
    
    def encode(*args)
      steps << Encoding.new(*args)
      self
    end

    def +(other_job)
      new_job = self.class.new(self.app)
      new_job.steps = steps + other_job.steps
      new_job
    end

    def num_steps
      steps.length
    end
    
    def apply
      steps[next_step..-1].each do |step|
        step.apply(self)
      end
      next_step = steps.length
    end

    def already_applied?
      next_step == steps.length
    end

    protected
    attr_writer :steps

    private
    
    attr_reader :next_step
    
    def resulting_temp_object
      apply unless already_applied?
      temp_object
    end

  end
end