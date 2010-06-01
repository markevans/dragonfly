module Dragonfly
  class Job
    
    # Processing job part
    class Process
      def initialize(name, *args)
        @name, @args = name, args
      end
      attr_reader :name, :args
      def apply(temp_object)
        temp_object.process(name, *args)
      end
      def to_a
        [:process, name, *args]
      end
    end
    
    # Encoding job part
    class Encoding
      def initialize(format, *args)
        @format, @args = format, args
      end
      attr_reader :format, :args
      def apply(temp_object)
        temp_object.encode(format, *args)
      end
      def to_a
        [:encoding, format, *args]
      end
    end
    
    def initialize(&block)
      @steps = []
    end
    
    attr_reader :steps

    def add_process(name, *args)
      steps << Process.new(name, *args)
    end
    
    def add_encoding(format, *args)
      steps << Encoding.new(format, *args)
    end

    def +(other_job)
      new_job = self.class.new
      new_job.steps = steps + other_job.steps
      new_job
    end

    def num_steps
      steps.length
    end
    
    def apply(temp_object)
      steps.inject(temp_object) do |tmp, step|
        step.apply(tmp)
      end
    end
    
    protected
    attr_writer :steps
  end
end